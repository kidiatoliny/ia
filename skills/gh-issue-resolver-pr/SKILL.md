---
name: gh-issue-resolver-pr
description: Resolve GitHub issues end-to-end with urgency-first execution and pull requests. Use when a user asks to analyze open issues, prioritize from most urgent to least urgent, implement fixes, run targeted validation, and open one or more PRs with clear summaries and links.
---

# GH Issue Resolver PR

## Overview
Use this skill to triage open GitHub issues, rank urgency consistently, fix issues in order, validate changes, and open PRs.

## Permission Bootstrap (First Run)
The platform permission model cannot be bypassed, but prompts can be minimized.

At the start of a long run, request persistent approvals (`prefix_rule`) for these command families:
- `git checkout`
- `git pull --ff-only`
- `git add`
- `git commit -m`
- `git push -u origin`
- `gh issue list`
- `gh issue view`
- `gh pr create`

After these are approved once, continue the full issue queue without pausing for repeated permission prompts.

## Workflow
1. Confirm repository and fetch open issues.
2. Prioritize issues by urgency using labels and impact.
3. Lock execution order by priority (highest to lowest) and do not skip ahead.
4. Work one issue at a time from highest to lowest urgency.
5. Implement minimal safe fix, then run targeted checks.
6. Commit with issue reference and open PR.
7. Move to next issue and repeat.
8. Continue until no open issues remain in scope, unless blocked by missing requirements or failing checks that require user direction.

## Priority Rules
Score urgency in this order:
1. Security/data loss/production outage bugs.
2. Regressions in critical flows (checkout, auth, payments, legal, invoices).
3. High-impact bugs with many users affected.
4. Deadlines and explicit urgency labels.
5. Older unresolved bugs.
6. Features, refactors, docs.

Map labels to base urgency if present:
- `critical`, `p0`, `severity:critical`, `security`: highest.
- `high`, `p1`, `severity:high`, `bug`: high.
- `medium`, `p2`: medium.
- `low`, `p3`, `chore`, `docs`: low.

If labels conflict with issue content, prefer issue content.

## Commands
List issues:
```bash
gh issue list --repo <owner>/<repo> --state open --limit 200 --json number,title,labels,createdAt,updatedAt,url
```

Prioritize with bundled script:
```bash
python3 <skill_dir>/scripts/prioritize_issues.py --input issues.json
```

Create branch:
```bash
git checkout -b codex/issue-<number>-<slug>
```

Open PR:
```bash
gh pr create --repo <owner>/<repo> --base <base-branch> --head codex/issue-<number>-<slug> --title "fix: <short title> (#<number>)" --body-file pr_body.md
```

## Implementation Rules
- Keep changes scoped to the current issue.
- Do not bundle unrelated refactors.
- Preserve behavior outside the reported bug.
- Add or adjust tests when risk warrants it.
- Run the narrowest meaningful validation first, then broader checks if needed.
- Stop and ask user before risky/destructive operations.

## PR Template
Use this structure:
- Problem: short statement with issue link.
- Root cause: what was wrong.
- Solution: what changed and why.
- Validation: commands/tests executed.
- Risk/rollback: known risk and fallback.

## Multi-Issue Execution
When user asks to resolve multiple issues:
1. Create one branch and exactly one PR per issue. Never combine multiple issues in the same PR.
2. Resolve strictly in urgency order, from highest to lowest priority.
3. Do not skip a higher-priority open issue unless it is blocked; if blocked, report blocker and then continue with the next issue.
4. Close or link issues in PR body using `Fixes #<number>` when appropriate.
5. Report progress after each PR with issue number, branch, and PR link.
6. After reporting, immediately start the next highest-priority open issue without waiting for another prompt.
7. Stop only when the prioritized list is exhausted or a hard blocker is found.

## Resources
- Priority details: `references/priority-rules.md`
- Sort helper: `scripts/prioritize_issues.py`
