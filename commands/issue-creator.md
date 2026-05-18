---
name: issue-creator
description: Creates a GitHub issue AND a linked Linear issue from a user request. Classifies intent, builds a structured English title + body, opens both issues, and cross-links them. Use when the user asks to file, report, open, or track a bug, feature, task, or doc item.
---

# Issue Creator

Creates a GitHub issue **and** a matching Linear issue, then links them both ways. If the Linear MCP is unavailable, fall through to GitHub-only mode and warn the user.

## Workflow

1. **Parse request.** Extract the core problem or desired outcome. Translate to English if the user wrote in another language.

2. **Classify type** as exactly one of: `bug`, `feature`, `task`, `documentation`.

3. **Resolve targets.**
   - **GitHub repo:** if not explicitly given, infer from `gh repo view --json nameWithOwner -q .nameWithOwner` in the current repo. Ask only if resolution fails.
   - **Linear team:** call `mcp__linear__list_teams`. If exactly one team exists, use it. Otherwise ask which team. Cache for the session.
   - **Linear project (always ask, never auto-pick).** Call `mcp__linear__list_projects` filtered by the chosen team. Show a numbered list and ask the user to pick the project this work will be tracked in. **Do not auto-match by repo name** — the upstream repo and the project that tracks the work are often different (e.g. work on `laravel-sisp` may be tracked in `nosferry.com`, the consumer product). If a previous session cached a choice for this repo, show it as the default but still require Y/n confirmation.
   - **Project-level dependencies (optional).** Ask:
     ```
     Does this work depend on changes in another Linear project? (y/N)
     ```
     If `y`: list projects across all teams (recents first), let the user pick one or more. Capture the chosen project URLs — no issue IDs needed.
   - **Issue-level blocker (optional, default skip).** Ask:
     ```
     Know a specific upstream issue that blocks this? (y/N — default N)
     ```
     Only if `y`: prompt for the Linear issue ID (e.g. `AKIRA-104`) or GitHub URL. Skip otherwise — project-level dependency above is usually enough.

4. **Build the title.** Short, explicit, English. Imperative for tasks/features ("Add X"), descriptive for bugs ("Cart total wrong when …").

5. **Build the body** (English, this exact template):

```markdown
## Summary
<one-paragraph problem or request>

## Context
- Source: <where request came from>
- Impact: <who/what is affected>
- Scope: <systems/files/features involved>

## Acceptance Criteria
- [ ] <criterion 1>
- [ ] <criterion 2>

## Depends on
- [<Project name>](<project url>)
<!-- Omit the section entirely if no project-level dependencies were declared in step 3. -->

## Notes
<optional implementation notes>
```

5b. **Resolve milestone (GitHub + Linear, best-fit-or-create).**

   Every issue MUST land on a milestone on both sides. Resolution order:

   1. **List open milestones.**
      - GitHub: `gh api repos/{owner}/{repo}/milestones?state=open`
      - Linear: `mcp__linear__list_milestones` filtered by the chosen project.
   2. **Evaluate best-fit** by scoring each candidate against the issue:
      - Title/scope keyword overlap (e.g. "auth", "billing", "payments", "perf") — strongest signal.
      - Release-version alignment when the issue is a bug/feature heading into a next release (e.g. `vX.Y.Z` milestone matches a bug that blocks that release per `package.json`/`composer.json`/`CHANGELOG.md`).
      - Type compatibility (a `documentation` issue does not belong on a `vX.Y.Z — Bugfix` milestone unless docs are explicitly in scope per the milestone description).
      - Due-date sanity (do not bind a new feature to a milestone whose target date is < 7 days away unless the user insists).
   3. **Pick or create:**
      - If exactly one strong match (score clearly above others) → propose it: `Milestone: <name>. confirm? (Y/n)`.
      - If multiple plausible matches → numbered menu, user picks.
      - If zero plausible matches → propose creating a new milestone, naming it per the same rule as `/clawpatch` Step 8b:
        - Next-release-bound issue → `vX.Y.Z — <short scope phrase>`.
        - Otherwise → `<scope phrase> (<YYYY-Qn or YYYY-MM>)`.
        Description (multi-paragraph) names the scope, why it matters, and exit criteria. Confirm with the user before creating; never auto-create a milestone silently.
      - GitHub create: `gh api -X POST repos/{owner}/{repo}/milestones -f title=… -f description=… -f due_on=…Z`.
      - Linear create: `mcp__linear__save_milestone` with `project`, `name`, `description`, `targetDate`.
   4. **Mirror across sides.** Whatever milestone the issue lands on in GitHub must have an equivalently-named milestone on the Linear project (and vice versa). If only one side has the milestone, create the missing side before opening the issue. Cache the GH↔Linear milestone pair in `~/.claude/projects/<cwd-slug>/memory/linear-mapping.md` under `milestones:` so future runs reuse it without re-prompting.

6. **Build labels.**
   - Always one type label: `type:bug`, `type:feature`, `type:task`, or `type:documentation`.
   - Preserve any repo-specific labels the user named.
   - Priority labels only when explicitly requested or clearly implied.

6b. **Duplicate guard (GitHub + Linear) — mandatory before any create.**

    Never open a second issue for a request that is already tracked. Check both sides:

    - GitHub: `gh issue list --repo {owner}/{repo} --state all --search "<keywords from title>" --json number,title,state,url,milestone` (include closed — surfacing a recently-closed regression matters). Also try a search by any error string or file path mentioned in the body.
    - Linear: `mcp__linear__list_issues` filtered by `team` + `project` with a `title` substring; widen the query to `state in (Triage, Backlog, Todo, In Progress, In Review)` first, then include `Done` if zero matches.

    For each candidate, present to the user (max 5, ranked by title overlap):
    ```
    Possible duplicate(s):
      [GH #123] <title> (open, milestone: vX.Y.Z)
      [LIN ENG-456] <title> (In Progress)
    options:
      1) link to <#123 / ENG-456> instead of creating new
      2) create new anyway (explain why)
      3) cancel
    ```
    If the user picks (1), stop the create flow and just cross-link/comment on the existing issue. If (2), proceed but include a `Related:` line in the body pointing at the prior issue. If (3), abort.

7. **Create the GitHub issue first.**
   - `gh api repos/{owner}/{repo}/issues --method POST --raw-field title=… --raw-field body=… --field labels=[…] --field milestone=<number>`
   - Always pass `milestone` (resolved in Step 5b). Never open without a milestone.
   - If a label does not exist in the repo, retry with the valid subset and mention which were skipped.
   - Capture the returned `html_url` and `number`.

8. **Create the Linear issue.**
   - Use `mcp__linear__save_issue` with: `team` (from step 3), `project` (from step 3 — the project the user explicitly picked), `title`, `description`, `milestone` (from step 5b — the Linear-side milestone name), and a label matching the type (`Bug`, `Feature`, `Task`, `Documentation` — create via `mcp__linear__create_issue_label` if missing, only when the user wants labels mirrored).
   - `milestone` is mandatory — never open a Linear issue outside a project milestone.
   - **Append the GitHub URL to the Linear description** under a `## Links` section so the connection is visible in Linear's UI even without attachments.
   - **If project-level dependencies were declared in step 3**, the `## Depends on` section in the body already lists them — no extra Linear field needed (Linear has no project-level dependency relation; the description carries the signal).
   - **If an issue-level blocker was named in step 3**, also pass `blockedBy: ["<upstream-id>"]` to `save_issue` so Linear renders the cross-issue edge.
   - Capture the returned Linear issue URL and identifier (e.g., `ENG-123`).
   - If the Linear MCP is not connected, follow the connection steps from the `/linear` command, then retry. If the user declines to connect, skip Linear and warn.

9. **Cross-link.**
   - **GitHub → Linear:** edit the GitHub issue body (or post a comment) appending `Linear: <linear-url>`. Prefer `gh issue edit <num> --body-file …` so the body keeps the structured template.
   - **Linear → GitHub:** already done in step 8 via the `## Links` section. If the connected Linear MCP exposes `create_attachment` / `create_attachment_from_upload`, also attach the GitHub URL as a Linear attachment for nicer rendering.

10. **Delegate to the Linear skill if needed.** If the user wants extra Linear-side work (assign, set priority/cycle/project, add comments, mirror sub-tasks), invoke `/linear` with the Linear issue ID rather than re-implementing those flows here.

11. **Report back, terse:**
    - Final title
    - Applied labels (GitHub + Linear)
    - GitHub URL
    - Linear URL (or "Linear skipped: <reason>")

## Quality Rules

- Title + body always written in English regardless of the user's language.
- One issue per request unless the user asks for separate tracking.
- Acceptance criteria are mandatory — never omit.
- Avoid vague language ("improve", "fix things"). Be specific.
- Do not create duplicate GitHub + Linear issues if either side already exists for the same request — Step 6b duplicate guard is mandatory, never bypassed. Search both sides (`gh issue list --search …` including closed; `mcp__linear__list_issues` with title filter, widening to Done if no open match) and offer to link before creating new.
- Every issue must land on a milestone on both sides. Reuse existing milestones whenever scope/version aligns; only create a new milestone with explicit user confirmation. GH and Linear milestones must be mirrored (same name, same target date) and cached in `linear-mapping.md`.
- Never expose tokens or secrets in issue bodies.
- Never auto-pick the Linear project from the repo name — always ask. Upstream code repo and consumer tracking project are often in different teams/projects. Cached defaults are fine; silent picks are not.
- Default to project-level dependencies (free-text URLs in `## Depends on`) over issue-level `blockedBy`. Only request a specific blocker ID when the user volunteers one.
