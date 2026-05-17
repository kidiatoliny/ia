---
description: Run the mandatory pre-commit / pre-push quality gate. Blocks on any rule violation across SOLID, file-size cap, naming, comments, AI-tells, secrets, dead code, tests, and breaking changes.
---

Invoke the `commit-guard` skill.

Arguments: $ARGUMENTS

Routing:

- If arguments contain "push" or "release" → run pre-push profile (full build + lint + test + all rules).
- If arguments empty or contain "commit", "check", "audit", "ship" → run pre-commit profile (cheap rules + staged scan).
- If arguments mention a path → scope checks to that path.

Always read `~/.claude/skills/commit-guard/SKILL.md` and all `~/.claude/skills/commit-guard/references/` files first. Apply the 10 mandatory rules. Block on any violation. Never auto-fix destructive issues without explicit confirmation. Surface a consolidated report table.
