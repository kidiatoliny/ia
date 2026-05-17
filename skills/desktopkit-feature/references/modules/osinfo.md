# osinfo

Runtime detection helpers shared by every other package in `desktopkit`.

`osinfo` exists so that no other package has to switch on `runtime.GOOS` directly. If a fact depends on the current operating system, it belongs here.

## Public API

| Symbol | Purpose |
| --- | --- |
| `Platform` | A value type describing the current OS in a typed, comparable way. |
| `Current()` | Returns the `Platform` of the running process. |
| `(Platform) IsDarwin()` | True on macOS. |
| `(Platform) IsLinux()` | True on Linux. |
| `(Platform) IsWindows()` | True on Windows. |
| `(Platform) String()` | The canonical name of the platform. |
| `ExecutableExtension()` | Returns `".exe"` on Windows, `""` elsewhere. |

## Example

```go
import "github.com/akira-io/desktopkit/osinfo"

platform := osinfo.Current()
if platform.IsWindows() {
    // ...
}
```

## Dependencies

None beyond the standard library.

## Errors

This package returns no errors.

## Related

- [shell](./shell.md) uses `osinfo` to compose candidate paths.
- [files](./files.md) uses `osinfo` to choose the OS-native reveal command.
