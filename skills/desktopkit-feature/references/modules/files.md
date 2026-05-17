# files

Filesystem actions that are visible to the user: opening a path with the default application, revealing a path in the platform's file manager, and moving a path to the system trash.

`files` does **not** read, write, or copy files. Use the standard library `os` and `io` packages for those concerns.

## Public API

| Symbol | Purpose |
| --- | --- |
| `OpenPath(path string) error` | Opens `path` with the user's default application. |
| `OpenURL(url string) error` | Opens `url` in the user's default browser. |
| `RevealInFileManager(path string) error` | Opens the file manager and selects `path`. |
| `ErrPathRequired` | Returned when an empty string was passed to any of the above. |
| `ErrUnsupportedPlatform` | Returned when the running OS is not implemented. |

## Platform mapping

| Function | macOS | Linux | Windows |
| --- | --- | --- | --- |
| `OpenPath` | `open <path>` | `xdg-open <path>` | `cmd /c start "" <path>` |
| `OpenURL` | `open <url>` | `xdg-open <url>` | `cmd /c start "" <url>` |
| `RevealInFileManager` | `open -R <path>` | `xdg-open <parent>` (no native reveal) | `explorer /select,<path>` |

Linux has no universal "select item" command. `RevealInFileManager` opens the parent directory and the caller is expected to communicate the file name through the UI.

## Example

```go
import "github.com/akira-io/desktopkit/files"

if err := files.OpenPath("/Users/kid/Pictures/hero.png"); err != nil {
    return err
}

if err := files.RevealInFileManager("/Users/kid/Documents/report.pdf"); err != nil {
    return err
}
```

## Errors

| Sentinel | When |
| --- | --- |
| `ErrPathRequired` | An empty path was provided. |
| `ErrUnsupportedPlatform` | The running OS is not implemented. |

OS process failures are wrapped with the operation name (`open path: ...`).

## Dependencies

None beyond the standard library and the helpers in [osinfo](./osinfo.md).

## Related

- [paths](./paths.md) — resolves the directories `files` then acts on.
- [shell](./shell.md) — when you need to spawn an arbitrary CLI rather than the OS default opener.
