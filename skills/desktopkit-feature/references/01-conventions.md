# Conventions

Every package in `desktopkit` follows the rules below. They are non-negotiable. If a contribution breaks one of these rules without justification, it is rejected.

## Naming

### Packages

- Lowercase, single word, no underscores or camelCase.
- Singular when the package is about a single concept (`shell`).
- Plural when the package primarily yields collections or grouped resources (`paths`).
- Never prefix with `desktopkit` — the import path already provides that context.

### Exported identifiers

- **Be verbose. Be explicit. Never abbreviate.**
  - `ResolveExecutable`, never `RslvExec`.
  - `RevealInFileManager`, never `ShowFile` or `Rvl`.
- Function names start with a verb in the imperative mood.
  - `OpenPath`, `WriteSecret`, `LocateBinary`.
- Constructors return a configured value, named after the value.
  - `paths.For("hyperion")` returns `*AppPaths`.
- Predicate functions start with `Is`, `Has`, or `Can`.
  - `IsAvailable`, `HasExtension`, `CanWrite`.

### Unexported identifiers

- Same verbose discipline. Internal short names hurt readability long-term.
- Helpers that only exist for testability are unexported and live next to their caller.

### Errors

- Sentinel errors: `ErrXxx`, declared in the package they relate to.
- Wrapped errors use `fmt.Errorf("%s: %w", action, err)` — never bare `err`.
- One sentinel per failure category, not one per call site.

## Function design

- **Single responsibility.** A function does one thing the name describes.
- **One success value plus one `error`.** Multiple return values are a code smell unless the second value is conventional (`ok bool`, `n int`).
- **No boolean flag parameters.** Branching on flags means two functions wearing one name. Split them.
- **No `interface{}`/`any` in public signatures.** Accept and return concrete types or named interfaces.
- **Options as structs, not variadics.** A function that takes options accepts `XxxOptions` so call sites are readable.

## Comments

- **Code is the documentation.** If the name does not explain the function, the name is wrong.
- **No inline `//` narration.** Comments explaining *what* the next line does are forbidden.
- **GoDoc on every exported symbol** — one or two sentences, ending with a period, describing intent, not implementation.
- **`// TODO:` is allowed**, one line, with the author's GitHub handle.

## Documentation

- Every package has a markdown file in `docs/modules/<package>.md`.
- The file covers: purpose, public API, examples per OS, error catalog, related modules.
- Examples in markdown must compile — they are extracted to `examples_test.go` by tooling later, so keep them runnable.
- `README.md` only links — long-form text belongs in `docs/`.

## SOLID, DRY, KISS

- **Single responsibility** — one package = one concern. No "utils" grab bag.
- **Open/closed** — extend by registering new options or implementations, not by editing existing ones.
- **Liskov** — interfaces are tiny, behavior is consistent across implementations.
- **Interface segregation** — prefer many small interfaces. A consumer should depend only on what it uses.
- **Dependency inversion** — packages depend on contracts in `desktopkit`, not on transitive third-party libraries.
- **DRY** — if the same OS switch appears twice, it lives in `internal/osinfo` or a shared helper.
- **KISS** — the simplest correct API wins. Generics, reflection, and goroutines are last resorts.

## Testing

- Every exported function has a test.
- Tests are named `TestX_Scenario` (e.g. `TestResolveExecutable_FallsBackToCandidates`).
- Cross-platform code uses `runtime.GOOS` switches inside tests and skips with `t.Skipf` rather than `//go:build` whenever possible.
- No mocks of stdlib — tests touch the real filesystem inside `t.TempDir()`.

## Module layout

```
<package>/
├── <package>.go        primary public API
├── <package>_test.go   tests for the public API
├── doc.go              package-level GoDoc block (mirrors docs/modules/<package>.md intro)
└── internal_xxx.go     unexported helpers, one concern per file
```

Anything not on this list does not belong in a module folder.
