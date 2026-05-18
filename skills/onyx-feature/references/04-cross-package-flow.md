# Cross-Package Flow — onyx (Go) <-> onyx-rs (Rust)

The two packages publish a mirrored module surface. A feature lands in **both** whenever the behavior is platform/OS-level and reusable across desktop apps. This file is the workflow for proposing, scaffolding, and shipping the mirror.

## Repos

| Lang | Repo | Local path | Distribution |
| --- | --- | --- | --- |
| Go | `github.com/akira-io/onyx` | `/Users/kid/Akira/Foundation/onyx` | Go modules (proxy) |
| Rust | `github.com/akira-io/onyx-rs` | `/Users/kid/Akira/Foundation/onyx-rs` | crates.io (Trusted Publishing) |

## Trigger Points

The mirror prompt fires in three places:

1. **Author mode completes** in one language — before reporting done, ask whether to mirror.
2. **Suggest mode option 1 accepted** — after extracting to the active-language package, ask whether to mirror.
3. **Pre-commit hook** — if a commit touches `Foundation/onyx/` and the same logic does not exist in `Foundation/onyx-rs/` (or vice versa), surface the mirror prompt.

## Mirror Decision Tree

```
Is the feature platform/OS-level (paths, files, shell, osinfo, clipboard, notify, keyring, ...)?
├── No → not onyx territory; skip mirror.
└── Yes
    ├── Does the sister package already have an equivalent symbol?
    │   ├── Yes → audit it: same name? same shape? same docs?
    │   │   ├── All match → nothing to do.
    │   │   └── Drift detected → propose update in sister to match.
    │   └── No → propose new mirror module/symbol in sister.
    └── Is the behavior genuinely language-specific (uses Go channels, Rust async, etc.)?
        ├── Yes → mirror not required, but document the asymmetry in both READMEs.
        └── No → mirror.
```

## Mirror Workflow

1. **Detect divergence**: list the symbols added/changed in the active package.
2. **Map names** Go ↔ Rust idiomatically:
   - `paths.For(app)` ↔ `paths::for_app(app)`
   - `shell.NewResolver().Lookup(x).Resolve()` ↔ `shell::Resolver::new().lookup(x).resolve()`
   - `osinfo.Current()` ↔ `osinfo::Platform::current()`
   - `osinfo.ExecutableExtension()` ↔ `osinfo::executable_extension()`
   - Sentinel errors: `shell.ErrBinaryNotFound` ↔ `shell::ShellError::BinaryNotFound`
3. **Mirror prompt** to user (one message):

   ```
   onyx-feature: mirror prompt.

   Just added to <lang>: <symbol list>.
   Sister package <other>: <missing | drift | up-to-date>.

   Proposed Rust/Go mirror:
     - <name>(<sig>) ↔ <name>(<sig>)
     - <name>(<sig>) ↔ <name>(<sig>)

   Options:
     1. Mirror now (recommended) — switch to sister author workflow.
     2. Mirror later — open a tracking issue in the sister repo.
     3. Skip — language-specific, document asymmetry in both READMEs.

   Which?
   ```

4. **On option 1**: switch to sister author workflow (use that language's adapter). Scaffold mirror symbol, doc, changelog. Run sister's lint gate. Self-audit.
5. **On option 2**: `gh issue create -R akira-io/<other> --title "Mirror <symbol> from <lang>"` with a body linking the active-language commit (once it lands).
6. **On option 3**: edit both READMEs to call out the asymmetry under a "Language differences" section.

## Commit Discipline

- **Separate commits per repo.** Never bundle Go + Rust changes in one commit. Each repo's CHANGELOG, lint, and CI run independently.
- Commit message can reference the sister: `feat(shell): add Resolver fallback (mirrors onyx-rs#42)`.
- Tag and release each repo on its own cadence. They do not need to share version numbers, only surface intent.

## Asymmetry Allowed

Some features will never mirror cleanly:

- Go-only: anything using `chan`, `context.Context` as runtime-level cancellation, `errgroup`.
- Rust-only: anything using `async fn`, `tokio`, lifetimes that don't translate.

When mirroring is skipped, both READMEs note the asymmetry under "Language differences" so consumers know what is and is not portable across the two crates.

## Lint / CI Parity Check

After mirroring, the two CI workflows must both be green:

| Check | Go (onyx) | Rust (onyx-rs) |
| --- | --- | --- |
| Format | `gofmt -l .` | `cargo fmt --check` |
| Static analysis | `go vet ./...` | `cargo clippy -D warnings` |
| Tests | `go test ./...` | `cargo test --all` |
| Docs | `docs/modules/<pkg>.md` present | `docs/modules/<mod>.md` present |
| CHANGELOG | `## [Unreleased]` updated | `## [Unreleased]` updated |

If either side is red, the mirror is not done.
