---
name: desktopkit-feature
description: >-
  Author or audit features in github.com/akira-io/desktopkit (Akira's
  cross-platform Go desktop utility library) under rigid conventions and
  modern Go best practices. Three modes: author (scaffold new package or
  function), audit (scan and report violations, no auto-fix), suggest
  (proactive extraction prompt). Triggers on keywords like "desktopkit",
  "desktop kit", "akira-io/desktopkit", "Foundation/desktopkit", or when
  user wants to add, create, implement, scaffold, or author a Go package,
  module, function, helper, or feature in the shared desktop utility
  library (cross-platform helpers — osinfo, paths, files, shell, clipboard,
  notify, keyring, etc.), or wants to audit, review, lint, or check Go
  code for naming conventions, SOLID, DRY, KISS, modern Go (generics,
  slices, maps, log/slog, errors.Join), error handling, doc/test layout,
  or semver/CHANGELOG compliance. Also triggers proactively, WITHOUT
  explicit desktopkit mention, when any Go feature in any consumer app
  touches runtime.GOOS, os/exec for system binaries (open, xdg-open,
  explorer, start), platform paths (XDG, AppData, ~/Library), filesystem
  reveal (Finder, Explorer, Nautilus), clipboard, notifications,
  keyring/secrets, default-app launching, native dialogs, single-instance
  lock, autostart, OS version detection, or switch runtime.GOOS / go:build
  per-OS branching; same for filenames like platform.go, os_darwin.go,
  paths_windows.go, or repeated OS conditionals across two or more files,
  or code duplicating an existing desktopkit package. desktopkit is
  consumer-agnostic — any Akira or third-party Go desktop app may depend
  on it; never assume a specific consumer.
---

# desktopkit-feature

Enforce desktopkit conventions when authoring or auditing code in `github.com/akira-io/desktopkit` (local path: `/Users/kid/Akira/Foundation/desktopkit`).

## Modes

Detect mode:

- **author** — "add X to desktopkit", "new package Y", "implement Z function", "scaffold ..."
- **audit** — "review", "audit", "check", "lint conventions", "is this compliant"
- **suggest** (proactive) — feature being written in consumer app shows desktopkit-territory signals (see below). Fires automatically, not user-invoked.

If ambiguous: existing files → audit. New work → author.

## Suggest Mode (Proactive Extraction Prompt)

Activate when ANY of these signals appear in code being written/edited (in ANY Go project, not just desktopkit):

**Code-level signals:**
- `runtime.GOOS` referenced outside `osinfo` package
- `switch runtime.GOOS` or `if runtime.GOOS == "..."` branches
- `//go:build darwin|linux|windows` constraint files for cross-platform helpers
- `exec.Command("open"|"xdg-open"|"explorer"|"start"|"cmd")` — file/url opening
- `exec.LookPath` for system binaries with multiple fallback paths
- Hand-rolled XDG (`XDG_CONFIG_HOME`, `XDG_DATA_HOME`, `XDG_CACHE_HOME`) logic
- `%AppData%`, `%LocalAppData%`, `os.UserConfigDir`, `os.UserCacheDir` per-OS branching
- `~/Library/Application Support`, `~/Library/Caches` paths
- Clipboard read/write via `pbcopy`/`pbpaste`/`xclip`/`wl-copy`/PowerShell
- Notification via `osascript`/`notify-send`/`powershell -Command`
- Keyring/Keychain/Credential Manager access
- Reveal-in-file-manager (`open -R`, `xdg-open <dir>`, `explorer /select`)
- Single-instance lock files in OS-specific dirs
- Autostart entries (LaunchAgents, .desktop autostart, Windows registry Run keys)
- Native open/save dialogs called directly via OS APIs

**Filename signals:**
- `platform*.go`, `os_*.go`, `*_darwin.go`/`*_linux.go`/`*_windows.go` with helper logic
- `paths.go`, `clipboard.go`, `notify.go`, `shell.go`, `keyring.go` in a consumer app's internal/

**Duplication signals:**
- Function does what `osinfo`/`paths`/`files`/`shell` (or other existing desktopkit package) already does
- Same OS-conditional pattern appears in two+ files within the project

### Suggest Action

When signal detected, BEFORE writing the inline code, surface ONE message:

```
desktopkit-feature: this looks like desktopkit territory.

Signal: <which signal triggered>
Existing package match: <name or "none — would be new package <suggested-name>">

Options:
  1. Extract to desktopkit (recommended) — I'll author the package under conventions, then import it here.
  2. Inline now, extract later — flag with TODO referencing desktopkit issue.
  3. Keep inline — app-specific, not reusable (explain why).

Which?
```

Do NOT auto-extract without user/agent confirmation. The point is the suggestion, not silent rewriting.

If running as sub-agent with no human in loop: default to option 1 (extract) UNLESS the logic is genuinely app-specific (uses consumer-specific domain types in the public signature). Log decision.

## Source of Truth

Skill ships with frozen copy of conventions in `references/`. Always read those first — they're self-contained, survive desktopkit folder moves.

Before doing anything, read (relative to this SKILL.md):

1. `references/01-conventions.md` — rigid naming, errors, function design, comment, test rules
2. `references/02-architecture.md` — cross-cutting, dependency, SOLID, semver rules
3. `references/03-release-flow.md` — CI changelog automation, conventional-commit map, release cutting
4. `references/modules/*.md` — reference shape for per-package docs (osinfo, paths, files, shell)

If `references/` disagrees with this SKILL.md, references win.

### Sync Check

After reading references, if live desktopkit repo reachable at `/Users/kid/Akira/Foundation/desktopkit/docs/` (or user provides path), diff against `references/`. If drift detected, surface it: "references/ out of date vs live docs — sync before proceeding?" Do NOT silently use stale refs or silently use live refs. User decides which is canonical, then sync.

To resync references manually:
```
cp <desktopkit>/docs/01-conventions.md ~/.claude/skills/desktopkit-feature/references/
cp <desktopkit>/docs/02-architecture.md ~/.claude/skills/desktopkit-feature/references/
cp <desktopkit>/docs/modules/*.md ~/.claude/skills/desktopkit-feature/references/modules/
```

## Go Language Standards (Hard Enforcement)

Target Go version: **latest stable** (1.23+). Use modern features. Reject pre-modern patterns.

### Modern Go Features (Required When Applicable)
- **Generics** (1.18+): use type parameters instead of `interface{}`/`any` for typed containers/helpers. `func Map[T, U any](s []T, f func(T) U) []U`.
- **`any`** alias over `interface{}` when an empty interface is truly required (rare — prefer generics).
- **`min`/`max`/`clear`** builtins (1.21+) over hand-rolled loops/conditionals.
- **`for range N`** integer iteration (1.22+): `for i := range 10` not `for i := 0; i < 10; i++`.
- **Loop variable per-iteration scoping** (1.22+): assume new semantics. Don't add `x := x` shadowing workarounds.
- **`slices`** package: `slices.Contains`, `slices.Sort`, `slices.Index`, `slices.Equal`, `slices.Concat`. Never write manual equivalents.
- **`maps`** package: `maps.Keys`, `maps.Values`, `maps.Clone`, `maps.Copy`. Never hand-roll.
- **`cmp`** package: `cmp.Or`, `cmp.Compare` for ordering.
- **`errors.Is` / `errors.As` / `errors.Join`** for error inspection and aggregation. Never compare errors with `==` (except for `io.EOF`).
- **`context.Context`** as first parameter of any function performing I/O, network, or long work. Never store context in a struct.
- **`log/slog`** (1.21+) for structured logging if logging is needed. Never `log` package, never `fmt.Println` for diagnostics.
- **`sync.OnceFunc` / `OnceValue` / `OnceValues`** (1.21+) over `sync.Once` + closure.
- **`atomic.Int64`/`Bool`/`Pointer[T]`** typed atomics (1.19+) over `atomic.AddInt64`/`LoadInt64` on raw `int64`.
- **`time.AfterFunc` / `context.WithTimeout`** — never `time.Sleep` for synchronization.
- **`os.ReadFile` / `os.WriteFile`** — never `ioutil.*` (deprecated).
- **`testing.T.Context()`** (1.24+) when available; `t.TempDir()`, `t.Setenv()`, `t.Cleanup()` always.

### Effective Go Mandatory Practices
- Accept interfaces, return concrete types. Define interfaces at consumer side, not producer.
- Zero values must be useful. A `var x Foo` should work without `NewFoo()` unless construction is non-trivial.
- Errors are values: handle locally, wrap with `%w`, never log + return (one or the other).
- Goroutines must have clear ownership and termination path. Always know who closes the channel.
- Channels: sender closes, never receiver. Unbuffered by default. Buffered only with documented capacity reason.
- `defer` for cleanup — file Close, mutex Unlock, span End. Check `Close()` error if write path.
- Mutex zero-value usable; never `sync.Mutex{}` literal in struct init.
- Use `io.Reader`/`io.Writer` over `[]byte`/`string` for streamable data.
- Prefer composition over embedding-for-inheritance. Embed only when promoting methods is intentional API.
- `String()` method only if value is genuinely human-printable; not as catch-all serialization.

### Forbidden Patterns
- `init()` functions — explicit setup only. Exception: registering drivers in registry pattern, with comment justifying.
- `panic` for control flow. Panic only on unrecoverable programmer error (nil receiver guard for required deps).
- `recover` outside of process-boundary handlers (HTTP middleware, RPC server top-level).
- Global mutable state. Package-level vars only for sentinel errors and true immutable defaults.
- `interface{}` / `any` in exported APIs (use generics).
- `reflect` unless absolutely no alternative — document why.
- `unsafe` — forbidden in desktopkit. PR must justify and isolate.
- `go func() { ... }()` without explicit lifecycle (context + done channel + recover at top).
- `time.Now()` directly in business logic — pass a clock or use `context` deadline.
- Naked returns in functions >5 lines.
- Stutter: `shell.ShellCandidates`, `paths.PathFor`. Use `shell.Candidates`, `paths.For`.

### Linting Gate
Before reporting done, run:
```
gofmt -l .         # must output nothing
go vet ./...       # must pass
go test ./...      # must pass
```
If `staticcheck` / `golangci-lint` available locally, run them too.

## Desktopkit Convention Rules (Hard Enforcement)

### Naming
- Packages: lowercase, single word, no underscore/camelCase. Singular for value types (`osinfo`, `shell`), plural only when package itself is collection (`paths`, `files` — operations on many).
- NEVER prefix package or symbol with `desktopkit`.
- Functions: imperative verb. `ResolveBinary` not `BinaryResolver`. No abbreviations (`Configuration` not `Cfg`, `Application` not `App` unless domain term).
- Predicates: `IsX`, `HasX`, `CanX`. Return `bool`.
- Constructors: named after value — `NewCandidates`, `For(appName)`. Not `Make`, not `Create`.
- Sentinel errors: `ErrXxx`, one per category, package-prefixed message: `errors.New("shell: binary not found")`.
- Constants: PascalCase exported, no `SCREAMING_SNAKE`.
- Receivers: short, consistent per type (`c Candidates`, `p Platform`).

### Function Design
- Single responsibility. If name has "and", split.
- Return `(value, error)` — never just `bool` for failure, never panic for recoverable.
- **NO boolean flag parameters** in public API. Split into two functions or pass options struct.
- **NO `interface{}` / `any`** in exported signatures. Use generics or concrete types.
- **NO variadic options.** Use options struct: `func Foo(opts FooOptions)`.
- Errors wrapped with `fmt.Errorf("action: %w", err)` — preserve chain.

### Comments
- **NO inline `//` narration.** Code self-documents.
- GoDoc required on every exported symbol. Start with symbol name. One sentence minimum.
- `// TODO:` allowed only with GitHub handle: `// TODO(@kidiatoliny): ...`
- No section dividers (`// --- Helpers ---`).
- No "what this does" block above functions — GoDoc covers it.

### File Layout per Package
```
<package>/
  <package>.go        # primary public API
  <package>_test.go   # tests
  doc.go              # package-level GoDoc only
  internal_<x>.go     # unexported helpers, grouped by concern
```
No `util.go`, no `helpers.go`, no `common.go`.

### Cross-Cutting
- Anything platform-conditional MUST go through `osinfo.Current()`. Never `runtime.GOOS` direct in any package except `osinfo` itself.
- Path operations route through `paths` package. Don't reinvent XDG/AppData logic.
- Shell/binary resolution routes through `shell.Candidates`.

### SOLID / DRY / KISS
- One package = one responsibility. If a package needs two unrelated types, split it.
- Depend on contracts (interfaces) when behavior varies; concrete types otherwise. No interfaces "just in case".
- No shared mutable state. No package-level vars except sentinel errors and immutable defaults.
- If logic appears in two packages, extract to a third. Never copy.

### Tests
- Names: `TestSymbol_Scenario` — `TestResolve_FailsWhenNothingMatches`.
- Cross-platform tests: `runtime.GOOS` + `t.Skipf` for unsupported OS. Never assume.
- No mocking stdlib. Use `t.TempDir()`, real filesystem, real binaries when reachable.
- One assertion concept per test. Multiple `t.Fatalf` for distinct failures OK.
- Table tests only when cases are truly parallel — don't force them.

### Documentation
- Every package has `docs/modules/<package>.md` with sections:
  1. Overview (one paragraph)
  2. API table (symbol | kind | summary)
  3. Platform behavior table (if cross-platform)
  4. Examples
  5. Errors
  6. Dependencies (other desktopkit packages)
  7. Related modules
- README only links to docs. No API in README.

### Versioning & Release
- Semver. Breaking change = major bump.
- Every release: CHANGELOG entry under `## [vX.Y.Z] - YYYY-MM-DD` with Added/Changed/Fixed/Removed sections (Keep-a-Changelog).
- New public symbol = `Added`. Signature change = `Changed` + major.

### Release Automation (CI-driven)

Read `references/03-release-flow.md` before touching changelog or release.

- **Conventional commits required** — `cliff.toml` parses prefixes and drops anything that does not match a parser rule. Use `feat:`, `fix:`, `refactor:`, `perf:`, `docs:`, `chore(deps):`. Never use `chore:` alone for a user-visible change (silently dropped).
- **CHANGELOG `## [Unreleased]` is human voice** — bot opens PR with first draft from git-cliff; human polishes wording before merge. Do NOT hand-edit `## [Unreleased]` directly on main if the changelog workflow is healthy; let the PR roll. Only override when bot output is wrong.
- **GitHub Release body is technical voice** — auto-generated by release workflow from git-cliff `--latest` between tags. Exhaustive log, not curated.
- **Cutting a release** — promote `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD`, insert fresh empty `## [Unreleased]` above, commit `chore(release): vX.Y.Z`, tag and push. Release workflow publishes automatically; do NOT manually create GitHub Releases.
- **Two surfaces, two voices** — CHANGELOG.md (curated story for users), GitHub Release (audit log for downstream maintainers). Do not duplicate one into the other.

When author mode adds a new public symbol, the commit message must use a prefix that maps to a CHANGELOG section. Otherwise the user's next release will silently omit the addition.

## Author Mode Workflow

1. Read the three doc files above.
2. Confirm package name and responsibility with user in ONE message if unclear; otherwise proceed.
3. Scaffold files:
   - `<package>/<package>.go` — exported types/functions with GoDoc
   - `<package>/doc.go` — `// Package <name> ...` only
   - `<package>/<package>_test.go` — `TestSymbol_Scenario` tests
   - `docs/modules/<package>.md` — full per-module doc
4. Update `CHANGELOG.md` — add `Added` entry under `## [Unreleased]`.
5. Update `README.md` packages list if section exists.
6. Run `go vet ./... && go test ./...` from `desktopkit/` root. Fix any failure before reporting done.
7. Self-audit using audit checklist below. Fix anything that fails.
8. Report: files created, tests passing, doc link.

Do NOT commit. User commits.

## Audit Mode Workflow

Target: a package path, a file, or "all".

For each Go file in scope, check:

```
[ ] Go modern features used (slices/maps/cmp pkgs, range-over-int, generics over any)
[ ] No ioutil.*, no interface{} in exports, no init() without justification
[ ] No panic for control flow, no global mutable state, no unsafe
[ ] context.Context first param on I/O funcs, never stored in struct
[ ] errors.Is/As/Join used, no == on errors (except io.EOF)
[ ] log/slog if logging; no log package, no fmt.Println diagnostics
[ ] Typed atomics (atomic.Int64 etc.) not raw int64 atomics
[ ] Zero values useful; channels closed by sender; defer for cleanup
[ ] gofmt clean, go vet clean, go test passes
[ ] No stutter (shell.Candidates not shell.ShellCandidates)
[ ] Package name: lowercase, single word, no underscore
[ ] No 'desktopkit' prefix in names
[ ] Every exported symbol has GoDoc starting with symbol name
[ ] No inline narration comments (// explaining what code does)
[ ] No section divider comments
[ ] TODO comments include GitHub handle
[ ] Function names: imperative verbs, no abbreviations
[ ] Predicates: Is/Has/Can prefix, bool return
[ ] Constructors: NewX or domain-named (For, From, Of)
[ ] Errors: ErrXxx sentinels, package-prefixed message
[ ] Errors wrapped with %w
[ ] No boolean flag parameters in exported funcs
[ ] No interface{} / any in exported signatures
[ ] No variadic options (uses options struct)
[ ] No shared mutable package-level state (only sentinel errors / immutable defaults)
[ ] runtime.GOOS only inside osinfo package
[ ] File layout: <pkg>.go, <pkg>_test.go, doc.go, internal_*.go (no util.go/helpers.go)
[ ] docs/modules/<pkg>.md exists with required sections
[ ] Tests named TestSymbol_Scenario
[ ] Cross-platform tests skip via t.Skipf
[ ] No stdlib mocking
```

Output format (Markdown):

```
# Audit: <target>

## Compliant
- <short bullet list>

## Violations
### <file>:<line> — <rule>
**Found:** `<excerpt>`
**Required:** <what should change>
**Why:** <one-line reason citing rule>

## Required Corrections
1. <imperative action>
2. ...
```

Do NOT auto-fix. Report only. Ask user to approve corrections, then apply.

## Communication

- Terse. Caveman mode honored when active.
- Cite the rule by section when reporting violation.
- Never invent a convention not in the docs. If user wants a new rule, propose it as a docs edit first.
- If conventions docs are unclear/contradictory, surface the conflict; do not silently pick a side.

## Output Requirement

Author mode ends with: file list + `go test ./...` result.
Audit mode ends with: violation count + corrections list.

Never produce code that fails any rule. Self-check before reporting done.
