---
description: Author, audit, or extract-suggest features for github.com/akira-io/onyx (Go) and github.com/akira-io/onyx-rs (Rust crate). Dual-language, mirrored module surface.
---

Invoke the `onyx-feature` skill.

Arguments: $ARGUMENTS

Routing:
- Detect target language first via project files (`go.mod` → Go, `Cargo.toml` → Rust). If both or neither, ask.
- If arguments contain "audit", "review", "check", "lint" → audit mode on the target path/package.
- If arguments contain "new", "add", "create", "scaffold", "implement", "author" → author mode for the named package/feature.
- If arguments empty or ambiguous → ask user which mode, listing: author / audit / suggest.

Always read `~/.claude/skills/onyx-feature/SKILL.md` and `~/.claude/skills/onyx-feature/references/` first. Follow every rule.

Lint gates before reporting done in author mode:
- Go (onyx): `gofmt -l . && go vet ./... && go test ./...` from `Foundation/onyx/`.
- Rust (onyx-rs): `cargo fmt --all -- --check && cargo clippy --all-targets -- -D warnings && cargo test --all` from `Foundation/onyx-rs/`.

After completing in one language, surface the mirror prompt for the sister package (see `references/04-cross-package-flow.md`).
