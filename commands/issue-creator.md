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

6. **Build labels.**
   - Always one type label: `type:bug`, `type:feature`, `type:task`, or `type:documentation`.
   - Preserve any repo-specific labels the user named.
   - Priority labels only when explicitly requested or clearly implied.

7. **Create the GitHub issue first.**
   - `gh api repos/{owner}/{repo}/issues --method POST --raw-field title=… --raw-field body=… --field labels=[…]`
   - If a label does not exist in the repo, retry with the valid subset and mention which were skipped.
   - Capture the returned `html_url` and `number`.

8. **Create the Linear issue.**
   - Use `mcp__linear__save_issue` with: `team` (from step 3), `project` (from step 3 — the project the user explicitly picked), `title`, `description`, and a label matching the type (`Bug`, `Feature`, `Task`, `Documentation` — create via `mcp__linear__create_issue_label` if missing, only when the user wants labels mirrored).
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
- Do not create duplicate GitHub + Linear issues if either side already exists for the same request — search first (`gh issue list --search …`, `mcp__linear__list_issues` with a title filter) and offer to link instead.
- Never expose tokens or secrets in issue bodies.
- Never auto-pick the Linear project from the repo name — always ask. Upstream code repo and consumer tracking project are often in different teams/projects. Cached defaults are fine; silent picks are not.
- Default to project-level dependencies (free-text URLs in `## Depends on`) over issue-level `blockedBy`. Only request a specific blocker ID when the user volunteers one.
