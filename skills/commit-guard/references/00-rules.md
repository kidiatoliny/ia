# Mandatory Rules — Universal

These 10 rules are non-negotiable. Apply to every language, every project, every commit and push.

## 1. File length — 300 lines hard cap

- Every source file must be ≤ 300 lines (including blank lines, excluding generated/vendored).
- At 301+, block. Surface a concrete split plan: which functions/types move to which new file, what to name them, how imports reshape.
- Generated files (proto, GraphQL codegen, migrations, `wailsjs/`) are exempt — they live in their own directories and are auto-detected by gitattributes/path.
- Test files share the cap. A `_test.go` over 300 lines is a smell that the production type has too many responsibilities.

## 2. Tests on every change

- Functional code change → matching test change (new or updated) in the same commit.
- Allowed reasons to skip, all of which must be stated explicitly in the commit body:
  - Pure refactor with zero behavior change (and the existing test suite passes unchanged).
  - Pure formatting / rename without behavior change.
  - Typo fix in copy/docs.
  - Generated code update.
- "I'll add tests later" is not an allowed reason.

## 3. Commit scopes

- Format: `type(scope): description`. Subject ≤ 72 chars.
- `type` ∈ {`feat`, `fix`, `refactor`, `perf`, `docs`, `chore`, `test`, `ci`, `revert`, `style`}.
- `scope` must come from the project's established scope set.
- If the project has no scope set, define one BEFORE the first commit:
  - Inspect top-level packages/folders.
  - Propose a scope list (e.g. `infra`, `domain`, `ui`, `api`, `cli`, `ci`, `deps`, `docs`).
  - Confirm with user and add to project `CLAUDE.md` under "Commit scopes".
- Never use ad-hoc scopes not in the set.

## 4. Naming — language-idiomatic, never invented

- Follow the community-standard convention for the language. Authoritative sources:
  - Go: official spec + `gofmt` + `golangci-lint`
  - PHP: PSR-1, PSR-12
  - JavaScript/TypeScript: Airbnb JS style guide, TypeScript handbook
  - Python: PEP 8, PEP 257
  - Rust: Rust API Guidelines, rustfmt defaults
  - Ruby: RuboCop community style guide
  - Java: Google Java Style Guide
- When a project has its own override in `CLAUDE.md`, project wins.
- Otherwise infer from existing code in the project (≥3 consistent examples).
- If neither: use the community source. Never invent a third convention.

## 5. Pre-push: full build, lint, test — blocking

- Before any `git push`, run the project's full build, lint, and test suite.
- Block on any failure. Do not push a red tree.
- Common runners (use what the project defines; if undefined, use language defaults):
  - Go: `gofmt -l . && go vet ./... && go test ./...`
  - PHP/Laravel: `vendor/bin/pint --test && vendor/bin/phpstan analyse && php artisan test`
  - TypeScript: `npm run lint && npm run typecheck && npm test && npm run build`
  - Python: `ruff check . && mypy . && pytest`
  - Rust: `cargo fmt --check && cargo clippy -- -D warnings && cargo test`
  - Ruby: `rubocop && rspec`

## 6. Comments — strict

See `02-comments-policy.md`. Summary: no narrative, no docblocks summarizing what code does, no section dividers, no obvious-code comments. Allowed only: static-analysis annotations, `// TODO(@handle):` one-liners, ≤1-line non-obvious-logic notes.

## 7. AI tells — blocked

See `03-ai-tells.md`. Summary: no emojis in code/copy/UI, no em-dash (`—`) in prose, no AI-shaped filler phrases. Override only when the user explicitly authorizes for the current change.

## 8. Secrets scan

- Scan staged diff for: AWS/GCP/Azure keys, private keys (`-----BEGIN`), API tokens (regex per provider), `.env` content patterns, hardcoded passwords, JWT tokens, database URLs with credentials.
- Tools to use when available: `git-secrets`, `trufflehog`, `detect-secrets`.
- On any ambiguous match (looks suspicious but might be a fixture), ASK the user, quoting the file:line and the matched string. Never proceed silently.

## 9. Dead code — always remove

- Run language-specific dead-code detector on staged changes:
  - Go: `go vet` + `unused` linter
  - TypeScript: `tsc --noEmit` + `ts-prune` or `knip`
  - PHP: PHPStan unused + `composer require --dev nunomaduro/phpinsights`
  - Python: `ruff` with `F401`, `F841`
  - Rust: `cargo +nightly udeps`, `cargo clippy`
- For each finding, report: symbol, file:line, impact (callers found / public API status / external dependency).
- Remove before commit. If removal is non-trivial (public API), surface as a breaking change (rule 10).

## 10. Breaking changes

- Any change to a public API surface requires:
  - Major-version bump in the next release.
  - `CHANGELOG.md` entry under `### Changed` or `### Removed` with the migration path.
  - Explicit explanation in the commit body of what breaks and why.
- Public API surface includes:
  - Exported types, functions, methods, constants (Go: capitalized; PHP: `public`; TS: exported; Python: not `_` prefixed; Rust: `pub`).
  - HTTP routes, GraphQL schema, gRPC service definitions.
  - Database schema affecting shared tables.
  - CLI flags, env vars, config file shape.
  - Public package layout (renaming/moving published packages).
- Run a best-effort scan for callers within the monorepo and across known consumer repos. List them.

## Exception protocol

User can authorize an exception per change with phrases like:

- "skip commit-guard"
- "allow emoji here"
- "ignore file-length for this file"
- "no test for this change because <reason>"

The exception:

- Applies only to the current change.
- Is logged in the final commit confirmation message in the conversation.
- Does NOT silently persist. To persist, user must add a rule to project `CLAUDE.md`.

Never apply your own exceptions. Never assume the user wants to skip because they "seem in a hurry". Always ask, citing the rule.
