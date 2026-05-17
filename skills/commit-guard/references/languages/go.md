# Go adapter

## Detection

- `go.mod` present in repo root, OR
- Staged files match `*.go`.

## Required commands

| Stage      | Command                                          |
|------------|--------------------------------------------------|
| Format     | `gofmt -l .`  (must output empty)                |
| Vet        | `go vet ./...`                                   |
| Lint       | `golangci-lint run` if config present, else skip |
| Test       | `go test ./...`                                  |
| Coverage   | `go test -cover ./...` (informational)           |
| Dead code  | `staticcheck ./...` if available, else `go vet`  |

## Naming

- Packages: lowercase, single word, no underscores.
- Exported: PascalCase. Unexported: camelCase.
- Errors: `ErrXxx` sentinels with package-prefixed message: `errors.New("shell: binary not found")`.
- Receivers: short, consistent per type (`c Candidates`).
- Predicates: `IsX`, `HasX`, `CanX`.

## Public API surface

Exported identifiers (capitalized) in all `.go` files outside `internal/` directories.

## Test detection

For modified `foo.go`, expect changes in `foo_test.go` (same package) or `foo_external_test.go`. If neither, surface as missing test.

## Common bad patterns to flag

- `runtime.GOOS` outside the `osinfo` package (in projects that have one).
- `interface{}` in exported signatures (use generics).
- `init()` without justification comment.
- `panic` for control flow.
- `recover` outside HTTP/RPC boundary.
- Global mutable state (`var x = ...` at package level for mutable types).
- `time.Sleep` for synchronization.
- `time.Now()` in business logic (pass clock or use ctx deadline).
- Naked returns in functions > 5 lines.
- `ioutil.*` (deprecated; use `os.*` / `io.*`).
- Stutter: `pkg.PkgFoo` (rename to `pkg.Foo`).
- `// TODO` without `(@handle)`.
- `log` package usage when `log/slog` is available (Go 1.21+).
- Manual loops where `slices`/`maps`/`cmp` builtins fit.
- `interface{}` aliased as `any` is OK, but prefer generics.

## File layout per package (project rule, project may override)

- `<pkg>.go`            primary API
- `<pkg>_test.go`       tests
- `doc.go`              package GoDoc
- `internal_<x>.go`     unexported helpers grouped by concern

No `util.go`, `helpers.go`, `common.go`.
