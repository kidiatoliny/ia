---
name: github-issue-creator
description: Creates GitHub issues from project-related user requests by classifying intent, generating concise titles and structured descriptions, applying labels, and opening issues through the GitHub API. Use when a user asks to create, file, report, or track a bug, feature, task, or documentation item in a repository.
---

# GitHub Issue Creator

## Follow This Workflow

1. Analyze the user request and extract the core problem or desired outcome.
2. Classify the issue type as exactly one of: `bug`, `feature`, `task`, `documentation`.
3. Translate the user request to English if needed, and create a short, explicit English title.
4. Create a structured body in English using this template:

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

5. Build labels:
- Always include one type label: `type:bug`, `type:feature`, `type:task`, or `type:documentation`.
- Preserve any repo-specific labels requested by the user.
- Add priority labels only when explicitly requested or clearly implied.

6. Create the issue through the GitHub API.
- Prefer `gh api repos/{owner}/{repo}/issues` with `title`, `body`, and `labels`.
- If labels do not exist in the repo, retry with the valid subset and mention skipped labels.

7. Return only what is needed:
- Final title
- Applied labels
- Created issue URL

## Repository Resolution Rules

- If the repository is explicitly provided, use it directly.
- If the repository is not provided, resolve from current git remote.
- Ask a follow-up question only when repository resolution is impossible.

## Quality Rules

- Keep titles concise and specific.
- Avoid ambiguous language.
- Do not omit acceptance criteria.
- Do not create multiple issues unless the user asks for separate tracking.
- Always write the GitHub issue title and body in English, regardless of the user's language.
