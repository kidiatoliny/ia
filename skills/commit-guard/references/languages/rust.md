# Rust adapter

## Detection

- `Cargo.toml` present, staged `*.rs` files.

## Required commands

| Stage      | Command                                       |
|------------|-----------------------------------------------|
| Format     | `cargo fmt --check`                           |
| Lint       | `cargo clippy --all-targets -- -D warnings`   |
| Test       | `cargo test`                                  |
| Build      | `cargo build --release` (pre-push)            |
| Dead code  | `cargo +nightly udeps` if available, else clippy `dead_code` lint |

## Naming

Rust API Guidelines.

- Crates/modules: `snake_case`.
- Types/Traits/Enums/Type aliases: `PascalCase`.
- Functions/methods/variables: `snake_case`.
- Constants and statics: `UPPER_SNAKE_CASE`.
- Lifetimes: short lowercase (`'a`, `'src`).
- Type parameters: single uppercase (`T`, `U`) or descriptive `Item`.

## Public API surface

`pub` items in `lib.rs` and re-exports through `pub use`. Workspace member crates' `lib.rs` API.

## Test detection

For modified `src/foo.rs`, expect:
- `#[cfg(test)] mod tests { ... }` block in `foo.rs`, OR
- `tests/foo.rs` integration test, OR
- `src/foo/tests.rs` if module is a directory.

## Common bad patterns

- `unwrap()` / `expect()` outside tests and `main` examples.
- `panic!` for recoverable errors.
- `unsafe` blocks without `// SAFETY:` comment justifying.
- `clone()` on large structures in hot paths.
- Manual `Drop` impls without justification.
- `#[allow(...)]` without rationale.
- Mod files (`mod.rs`) when using 2018+ edition style (`foo.rs` + `foo/` works).
- `pub` items missing doc comments (`///`).

## File length

300-line cap. Long impl blocks: extract into trait + impl files (`foo.rs` + `foo/impls.rs`).
