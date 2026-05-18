# Rust Adapter — `onyx-rs` crate

Crate: `onyx` on crates.io. Repo: `github.com/akira-io/onyx-rs`. Local path: `/Users/kid/Akira/Foundation/onyx-rs`.

Mirrors the Go `onyx` module surface (`osinfo`, `paths`, `files`, `shell`, ...) with Rust idioms. Every Go rule has a Rust counterpart here. If a Go rule has no analog (e.g. `runtime.GOOS`), the equivalent constraint applies to the Rust mechanism (`cfg!(target_os)` / `std::env::consts::OS`).

## Rust Language Standards (Hard Enforcement)

Target edition: **2021**. MSRV: stable Rust (latest minus one). Use modern idioms; reject legacy patterns.

### Modern Idioms (Required)

- **`Result<T, E>` + `?`** — never `unwrap()` / `expect()` in library code. `expect` allowed only in tests with explanatory string.
- **`thiserror`** for typed library errors — one enum per package, variants `#[error("...")]` package-prefixed (`"shell: binary not found"`).
- **`anyhow`** only in bins/examples, never in library crates.
- **`PathBuf` / `&Path`** for paths — never raw `String`.
- **`OsStr` / `OsString`** when crossing the FFI/OS boundary (env vars, args).
- **`std::env::var_os`** over `std::env::var` for paths/binaries (Windows uses non-UTF-8 paths).
- **`Option::ok_or` / `ok_or_else`** to lift `None` to `Err` — never panic on `None`.
- **`let ... else`** for early returns when binding from `Option`/`Result`.
- **`if let` chains** (stable on 2021+ where applicable).
- **Iterators over loops** — `iter().map().collect()` preferred to manual `for` push.
- **`derive(Debug, Clone, ...)`** on public types where it makes sense; do not implement by hand.
- **`#[non_exhaustive]`** on public enums/structs that may grow.
- **`#[must_use]`** on builder methods and pure functions returning `Result`/`Option`.
- **Standard library first** — pull in a crate only when std cannot do it cleanly. Document the choice in the module doc.

### Forbidden Patterns

- `unwrap()` / `expect()` outside `#[cfg(test)]` or `tests/`.
- `panic!` for control flow. Panic only on programmer errors (poisoned mutex, broken invariant).
- `unsafe` — forbidden in `onyx-rs`. Justify with a doc comment + isolate behind a safe API if ever needed.
- Global mutable state. `static mut` is banned. Use `OnceLock`/`LazyLock` for read-only globals.
- `lazy_static!` macro — use `std::sync::OnceLock` / `LazyLock` (stable).
- Reading `cfg!(target_os = ...)` or `std::env::consts::OS` outside the `osinfo` module.
- `String` allocations on hot paths when `&str` would do.
- Reimplementing `which` / `dirs` / `directories` semantics inline — route through onyx-rs modules.
- Trait objects (`Box<dyn Trait>`) in public APIs when generics work.
- Catch-all `From<...> for Error` implementations that erase context.

### Lint Gate

Before reporting done, run:

```sh
cargo fmt --all -- --check    # must pass
cargo clippy --all-targets --all-features -- -D warnings
cargo test --all
```

If `cargo doc --no-deps` is part of CI, run it locally too.

## Onyx Convention Rules (Rust-specific)

### Naming

- Crates: `onyx` (the published name). Internal modules: lowercase, single word, no underscore (`osinfo`, `paths`, `files`, `shell`).
- Types: `PascalCase` (`Resolver`, `Platform`, `ShellError`).
- Functions / methods / variables: `snake_case` (`resolve`, `is_path_like`, `look_path`).
- Constants / statics: `SCREAMING_SNAKE_CASE`.
- Predicates: `is_*`, `has_*`, `can_*`. Return `bool`.
- Constructors: `new` for trivial, `for_app` / `from_env` for domain-named. Never `make_*` / `create_*`.
- Error enum variants: `BinaryNotFound`, `InvalidPath`. No `Err` prefix on variants (the enum name is `ShellError`).
- No `Onyx` prefix on any item.
- No stutter: `shell::Resolver`, not `shell::ShellResolver`.

### Function Design

- Single responsibility. Split on "and" in the name.
- Return `Result<T, ModuleError>` — never `bool` for failure, never panic for recoverable.
- **No boolean flag parameters** in public API. Two functions or an options struct.
- **No untyped `Box<dyn Any>`** in public signatures. Use generics or concrete enums.
- **Prefer builder structs** to long arg lists when 3+ params. `Resolver::new().lookup("x").resolve()` style.
- Errors propagate with `?`; only wrap when adding context (`.map_err(|e| Error::Wrapped(e))`).

### Comments / Docs

- **No inline narration.** Code self-documents.
- `///` doc comments on every public item (`pub fn`, `pub struct`, `pub enum`, `pub trait`). One sentence minimum, starts with the item name in prose.
- `//!` module-level doc at the top of each `mod.rs` / `lib.rs`. One paragraph describing the module's responsibility.
- `// TODO(@kidiatoliny): ...` allowed; no other todo flavors.
- No section dividers (`// ---- helpers ----`).
- Doctests where the example is short and meaningful. Don't pad with trivial examples.

### File Layout per Module

```
src/
  lib.rs                  // re-exports the public surface; pub mod osinfo; pub mod paths; ...
  <module>/
    mod.rs                // public API + #[cfg(test)] mod tests
tests/                    // integration tests across modules
```

For tiny modules, a single `src/<module>.rs` file is acceptable; promote to `<module>/mod.rs` when it grows past ~200 lines or needs internal submodules.

No `util.rs`, no `helpers.rs`, no `common.rs`.

### Cross-Cutting

- Anything platform-conditional MUST route through `osinfo`. Never `cfg!(target_os)` / `std::env::consts::OS` outside the `osinfo` module.
- Path operations route through `paths`.
- Binary resolution routes through `shell::Resolver`.

### Tests

- Co-located unit tests under `#[cfg(test)] mod tests { ... }` at the bottom of each `mod.rs`.
- Integration tests in `tests/<scenario>.rs` when they cross modules.
- Test names: `snake_case`, scenario-first: `resolve_fails_when_nothing_matches`, `resolve_finds_explicit_path`.
- No mocking std. Use `tempfile::tempdir()`, real fs, real `PathBuf`.
- One assertion concept per test.

### Documentation

- Every public module has `docs/modules/<module>.md` mirroring the Go module doc shape (overview, API table, platform table, examples, errors, deps, related).
- README links to docs; no API surface in README beyond the before/after teaser.

### Versioning & Release

- Semver. Breaking change = major bump.
- `Cargo.toml` `version` is the source of truth. Tag `vX.Y.Z` triggers `publish.yml`, which verifies the tag matches `Cargo.toml`, runs tests, authenticates with crates.io via OIDC (Trusted Publishing), publishes, and creates a GitHub Release.
- CHANGELOG flow identical to Go side; see `references/03-release-flow.md`.

### Release Automation

- **First-time bootstrap**: crate must exist on crates.io before Trusted Publishing can be configured. Use a one-time API token (`publish-new` scope), `cargo publish --token <token>`, configure Trusted Publisher in the crate settings (Publisher: GitHub, Repo: `akira-io/onyx-rs`, Workflow: `publish.yml`, Environment: `release`), revoke token.
- **Subsequent releases**: bump `Cargo.toml`, promote `## [Unreleased]` to `## [X.Y.Z]`, commit `chore(release): vX.Y.Z`, tag `vX.Y.Z`, push. CI handles the rest.
- GitHub Environment `release` must exist (optional required reviewers gate).

## Author Workflow (Rust)

1. Read this file + `references/02-architecture.md` + `references/03-release-flow.md`.
2. Confirm module name + responsibility (ONE question if unclear).
3. Scaffold:
   - `src/<module>/mod.rs` with `//!` doc + public surface + `#[cfg(test)] mod tests`
   - or `src/<module>.rs` for small modules
   - Re-export from `src/lib.rs`: `pub mod <module>;`
   - `docs/modules/<module>.md`
4. `CHANGELOG.md` — `Added` entry under `## [Unreleased]`.
5. `README.md` modules table updated.
6. Run lint gate (`fmt --check`, `clippy -D warnings`, `test --all`).
7. Self-audit checklist.
8. Report: files, tests, doc link.
9. Mirror prompt to Go.

Never commit. User commits. Separate commits per repo.

## Audit Checklist (Rust)

```
[ ] cargo fmt clean
[ ] cargo clippy -D warnings clean
[ ] cargo test --all passes
[ ] No unwrap()/expect() in non-test code
[ ] No panic! for control flow
[ ] No unsafe
[ ] No static mut, no lazy_static! (use OnceLock/LazyLock)
[ ] cfg!(target_os) / std::env::consts::OS only inside osinfo
[ ] All public items have /// doc starting with item name
[ ] Module-level //! doc on every mod.rs
[ ] No inline narrative comments
[ ] No section dividers
[ ] TODO comments include @kidiatoliny
[ ] Types PascalCase, functions/vars snake_case, constants SCREAMING_SNAKE_CASE
[ ] No Onyx prefix; no stutter (shell::Resolver, not shell::ShellResolver)
[ ] Errors via thiserror enum, package-prefixed messages
[ ] Errors propagated with ?; wrapping only adds context
[ ] No boolean flags in public APIs
[ ] No Box<dyn Any> in public APIs
[ ] PathBuf/Path for paths; OsStr/OsString at OS boundary
[ ] std::env::var_os used (not var) for paths
[ ] anyhow absent from library code
[ ] Builders used for 3+ param constructors
[ ] File layout: src/<mod>/mod.rs or src/<mod>.rs; no util.rs/helpers.rs/common.rs
[ ] docs/modules/<mod>.md exists with required sections
[ ] Tests co-located under #[cfg(test)] mod tests; integration in tests/
[ ] Test names snake_case, scenario-first
[ ] No std mocking; uses tempfile + real fs
[ ] Cargo.toml version matches latest CHANGELOG section (or Unreleased)
```

Output format identical to Go audit (Compliant / Violations / Required Corrections).
