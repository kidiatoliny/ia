# PHP / Laravel adapter

No hard dependency on laravel-boost — works on any PHP project. When the project does ship boost, leverage its MCP tools for richer validation.

## Detection

- PHP: `composer.json` present, OR staged `*.php` files.
- Laravel: `artisan` file at repo root and `laravel/framework` in `composer.json`.
- laravel-boost: `laravel/boost` in `composer.json` require/require-dev (any version), OR `.mcp.json` / project config exposing boost MCP server, OR `php artisan list | grep boost` returns boost commands.

When boost is detected, prefer its tools over generic fallbacks (faster, version-aware, project-aware).

## Boost integration (when present)

Use these boost MCP tools as part of validation:

| Need                         | Boost tool                | Fallback when boost absent          |
|------------------------------|---------------------------|-------------------------------------|
| Docs / API reference         | `search-docs`             | manual WebFetch laravel.com/docs    |
| Artisan command introspection| `list-artisan-commands`   | `php artisan list`                  |
| Verify route exists          | `get-absolute-url`        | parse `php artisan route:list`      |
| Eloquent / query smoke test  | `tinker`                  | none — surface as "boost recommended" |
| DB read (schema, sample row) | `database-query`          | none — ask user to run query        |
| Browser console errors       | `browser-logs`            | none — ask user                     |

Boost tools are version-pinned to the project's Laravel + package versions, so docs and command lists are accurate. Do not WebFetch generic docs when boost is available.

## Required commands

Use what the project defines in `composer.json` scripts when present. Fallback defaults:

| Stage           | Command                                      |
|-----------------|----------------------------------------------|
| Format check    | `vendor/bin/pint --test`                     |
| Static analysis | `vendor/bin/phpstan analyse`                 |
| Test            | `vendor/bin/pest` or `vendor/bin/phpunit`    |
| Test (Laravel)  | `php artisan test`                           |

If Pint is not installed, fall back to `vendor/bin/php-cs-fixer --dry-run` or surface "no formatter configured" and ask.

## Naming

- PSR-1 + PSR-12.
- Classes/Interfaces/Traits/Enums: `PascalCase`, one per file, filename matches.
- Methods: `camelCase`.
- Properties: `camelCase`.
- Constants: `UPPER_SNAKE_CASE`.
- Variables: `$camelCase`.
- Namespaces follow PSR-4 directory layout.

## Public API surface

- `public` methods/properties on classes outside `Internal\` / `Tests\` namespaces.
- Routes (HTTP).
- Console commands (artisan signature).
- Database migrations (schema changes).
- Published config keys.

## Test detection

For modified `app/Foo/Bar.php`, expect a change in `tests/Feature/Foo/BarTest.php` or `tests/Unit/Foo/BarTest.php`. Pest projects: `*Test.php` anywhere in `tests/`.

## Common bad patterns to flag

- Inline validation in controllers (use Form Requests).
- `$fillable` arrays in models when project uses `Model::unguard()`.
- Facades inside domain logic (`Auth::`, `DB::`) — prefer helpers (`auth()`, `DB::` is OK in repository layer) and depend on contracts.
- `dd()`, `dump()`, `var_dump()`, `print_r()`, `error_log()` in staged code.
- `@` error suppression operator.
- `eval()`.
- Raw SQL where Eloquent or query builder fits.
- Missing `declare(strict_types=1);` at file top in new files.
- Missing return types on public methods.
- Inline closures with `use` capturing many variables (split into method).
- Mass-assignment without `$guarded` or `$fillable` discipline.

## Laravel-specific

- Actions in `app/Actions/` with `handle()` (not `execute()`).
- Single-method controllers use `__invoke()`.
- Use `route()` with named routes, not URL strings.
- Use `config()` not `env()` outside config files.
- API responses use `JsonResource` / `ResourceCollection`, not raw arrays.
- Form Requests for validation.
- Observers via `#[ObservedBy(...)]` attribute.
- Migrations: include all column attributes when modifying.
- UUIDs: `foreignUuid()` for FKs, `HasUuids` trait on models.
- Pivot tables: alphabetical (`project_role`), `withTimestamps()` if needed.

## Boost-augmented checks

When boost is present, the following checks become MANDATORY rather than best-effort:

- **Route validation**: any new/modified controller route must be verified via `get-absolute-url` to confirm the route is registered.
- **Artisan command verification**: new commands must appear in `list-artisan-commands` before commit.
- **Doc-grounded API usage**: if the change uses a Laravel/Inertia/Pest API, prefer behavior verified via `search-docs` for the project's exact version. Cite the doc reference in the commit body when the API is non-trivial.
- **Schema sanity**: when staged migrations touch existing tables, run `database-query` (read-only) to confirm assumptions about existing rows/types before commit.

When boost is absent, the above remain recommended but not blocking. Surface "boost would speed this up" as info in the report.

## File length applies normally (300-line cap)

PHP class files commonly drift over 300 lines via wide property/method blocks. Split into traits, value objects, or smaller classes by responsibility before hitting the cap.
