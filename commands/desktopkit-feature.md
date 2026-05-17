---
description: Author, audit, or extract-suggest features for github.com/akira-io/desktopkit under rigid conventions and modern Go best practices.
---

Invoke the `desktopkit-feature` skill.

Arguments: $ARGUMENTS

Routing:
- If arguments contain "audit", "review", "check", "lint" → audit mode on the target path/package.
- If arguments contain "new", "add", "create", "scaffold", "implement", "author" → author mode for the named package/feature.
- If arguments empty or ambiguous → ask user which mode, listing: author / audit / suggest.

Always read `~/.claude/skills/desktopkit-feature/SKILL.md` and `~/.claude/skills/desktopkit-feature/references/` first. Follow every rule. Run `gofmt -l . && go vet ./... && go test ./...` from desktopkit root before reporting done in author mode.
