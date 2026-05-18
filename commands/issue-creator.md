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
   - **Linear team:** if not given, call `mcp__linear__list_teams` and pick the obvious match (single team → use it; multiple → ask which). Cache the team key for the session.

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
   - Use `mcp__linear__save_issue` (or `mcp__linear__create_issue` if that's what the connected server exposes) with: `team`, `title`, `description`, and a label matching the type (`Bug`, `Feature`, `Task`, `Documentation` — create via `mcp__linear__create_issue_label` if missing, only when the user wants labels mirrored).
   - **Append the GitHub URL to the Linear description** under a `## Links` section so the connection is visible in Linear's UI even without attachments.
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
