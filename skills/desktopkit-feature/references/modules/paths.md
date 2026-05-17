# paths

Resolves the canonical configuration, data, cache, and log directories for an application on macOS, Linux, and Windows.

`paths` answers exactly one question: *"Where should my application keep its files for the current user?"*.

It does **not** create directories. It does **not** write files. Both of those concerns belong to `files`.

## Public API

| Symbol | Purpose |
| --- | --- |
| `For(applicationName string) *AppPaths` | Builds a resolver scoped to a single application. |
| `(*AppPaths) Config() (string, error)` | Returns the absolute path to the user's configuration directory. |
| `(*AppPaths) Data() (string, error)` | Returns the absolute path to the user's data directory. |
| `(*AppPaths) Cache() (string, error)` | Returns the absolute path to the user's cache directory. |
| `(*AppPaths) Logs() (string, error)` | Returns the absolute path to the user's log directory. |
| `(*AppPaths) Name() string` | Returns the application name passed to `For`. |
| `ErrMissingApplicationName` | Returned when `For` was called with an empty string. |

## Platform mapping

| Method | macOS | Linux | Windows |
| --- | --- | --- | --- |
| `Config()` | `~/Library/Application Support/<App>` | `$XDG_CONFIG_HOME/<App>` (default `~/.config/<App>`) | `%AppData%\<App>` |
| `Data()` | `~/Library/Application Support/<App>` | `$XDG_DATA_HOME/<App>` (default `~/.local/share/<App>`) | `%AppData%\<App>` |
| `Cache()` | `~/Library/Caches/<App>` | `$XDG_CACHE_HOME/<App>` (default `~/.cache/<App>`) | `%LocalAppData%\<App>\Cache` |
| `Logs()` | `~/Library/Logs/<App>` | `$XDG_STATE_HOME/<App>/logs` (default `~/.local/state/<App>/logs`) | `%LocalAppData%\<App>\Logs` |

The application name is used as-is. Callers that want a slugified folder name should slugify before calling `For`.

## Example

```go
import "github.com/akira-io/desktopkit/paths"

app := paths.For("Hyperion")

config, err := app.Config()
if err != nil {
    return err
}

logs, err := app.Logs()
if err != nil {
    return err
}
```

## Errors

| Sentinel | When |
| --- | --- |
| `ErrMissingApplicationName` | `For` was called with an empty string. |

All other failures bubble up from `os.UserConfigDir`, `os.UserCacheDir`, or environment variable parsing, wrapped with the operation name.

## Dependencies

None beyond the standard library.

## Related

- [files](./files.md) — creates and acts on the directories `paths` resolves.
- [osinfo](./osinfo.md) — `paths` uses it to choose the right convention.
