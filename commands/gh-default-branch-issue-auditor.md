---
name: gh-default-branch-issue-auditor
description: Analyze a repository default branch, discover actionable engineering problems, prioritize by impact and urgency, and create high-quality GitHub issues remotely with clear technical context and implementation guidance. Use when a user asks to audit code quality, reliability, regressions, security risks, or technical debt and wants issues opened automatically in GitHub.
---

# GH Default Branch Issue Auditor

## Overview
Use this skill to audit the default branch, identify concrete problems worth tracking, assign consistent priority (`P0`-`P3`), and open detailed GitHub issues remotely.

## Required Outcome
- Analyze real repository risk on the default branch.
- Create only actionable issues with reproducible evidence.
- Open issues remotely in GitHub with priority labels and implementation guidance.

## Workflow
1. Resolve repository and default branch:
```bash
gh repo view --json nameWithOwner,defaultBranchRef -q '.nameWithOwner + " " + .defaultBranchRef.name'
```

2. Sync and inspect default branch:
```bash
git fetch --all --prune
git checkout <default-branch>
git pull --ff-only
```

3. Build findings from evidence, not guesses:
- Inspect high-risk areas first: auth, payment, checkout, data writes, background jobs, access control, migrations.
- Run targeted checks when useful: tests, static analysis, linters.
- Record proof for each finding (file paths, failing tests, logs, or reproducible steps).

4. Remove duplicates before creating issues:
```bash
gh issue list --repo <owner>/<repo> --state open --limit 200 --json number,title,labels,url
```
- Skip findings already tracked by equivalent open issue title/scope.

5. Assign priority using `references/priority-model.md`.

6. Prepare issue content using `references/issue-template.md`.

7. Create issues remotely:
- Preferred: use `scripts/publish_issues.py` for batch creation.
- Alternative: create individually with `gh api repos/<owner>/<repo>/issues`.

8. Report results:
- Created issue URL
- Priority
- Short reason for priority
- Duplicate skips (if any)

## Quality Bar For Every Issue
- One issue per atomic problem.
- Clear impact and affected scope.
- Concrete reproduction or detection path.
- Practical implementation direction.
- Test/validation criteria that define completion.

## Language And Consistency
- Write GitHub issue title/body in English.
- Keep titles concise and specific.
- Keep body structured and implementation-focused.

## Resources
- Priority rubric: `references/priority-model.md`
- Issue structure: `references/issue-template.md`
- Batch publisher: `scripts/publish_issues.py`
