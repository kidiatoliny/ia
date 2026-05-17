# Architecture

`desktopkit` is a collection of small, independently importable Go packages. There is no central runtime, no init order, no hidden state. Each package exposes a focused API and depends on the standard library plus, when justified, one or two community libraries.

## Layout

```
desktopkit/
├── paths/        application directory resolution
├── files/        filesystem actions visible to the user
├── shell/        process spawning and binary discovery
├── osinfo/       runtime detection helpers (shared)
├── clipboard/    text and image clipboard (planned)
├── notify/       system notifications (planned)
└── keyring/      secret storage in the OS credential store (planned)
```

Every leaf package satisfies these rules:

- Self-contained — it can be imported alone.
- Zero side effects on import.
- One concern, one responsibility, named after the concern.

## Cross-cutting

A single shared helper package, `osinfo`, encapsulates the `runtime.GOOS` switch and the small handful of derived facts (executable extension, default file manager binary, etc.). No other package switches on `GOOS` directly — they ask `osinfo`.

This is the **DRY guarantee**: if Apple renames Finder or Microsoft replaces `explorer.exe`, exactly one file changes.

## Dependencies

Each package declares its third-party dependencies in its own `doc.go` header. Adding a new dependency requires:

- Justification in the pull request description.
- A line in `docs/modules/<package>.md` under `Dependencies`.
- An entry in `CHANGELOG.md` under the package's version.

Approved dependency principles:

- **Prefer a small dedicated library** over an OS switch when the library is mature and pure Go.
- **Prefer an OS switch** when the only available library is heavier than the OS switch it replaces.
- **Never depend on a UI toolkit** from a utility package.

## Errors

Errors are values, not control flow. Every package exposes:

- Sentinel errors for the categories the caller might reasonably want to handle (`ErrBinaryNotFound`, `ErrUnsupportedPlatform`).
- Wrapped errors via `fmt.Errorf("%s: %w", action, cause)` for everything else.

Callers handle errors with `errors.Is(err, somePackage.ErrXxx)`.

## Versioning

- Semver. Tags look like `v0.3.1`.
- Pre-1.0: minor bumps are allowed to break the API.
- Post-1.0: only major bumps break the API.
- Every release ships with `CHANGELOG.md` entries grouped by package.

## SOLID applied

- **Single responsibility** — `paths` resolves directories. It does not create them. `files` creates and acts on them.
- **Open/closed** — `shell.ResolveExecutable` accepts a `Candidates` value built by the caller. New search strategies extend `Candidates` without changing the resolver.
- **Liskov** — implementations of the same interface (planned: `clipboard.Provider`, `notify.Provider`) behave identically across operating systems from the caller's perspective.
- **Interface segregation** — `osinfo.Platform` is a value, not an interface. Interfaces appear only where multiple implementations exist.
- **Dependency inversion** — application code depends on `desktopkit/files.OpenPath`, not on `github.com/skratchdot/open-golang`. Swapping the underlying library is a one-package change.

## Boundaries

`desktopkit` does not own state. It does not write logs. It does not configure anything globally. If you need logging, pass a `*slog.Logger` into the option struct. If you need cancellation, pass a `context.Context`.

This keeps each package replaceable, testable, and embeddable inside any host (Wails, Fyne, Tauri-via-CGo, plain CLI).
