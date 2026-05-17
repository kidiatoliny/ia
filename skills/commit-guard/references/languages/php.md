# PHP / Laravel adapter

No dependency on laravel-boost. Works on any PHP project, with extra rules when Laravel is detected.

## Detection

- `composer.json` present, OR staged `*.php` files.
- Laravel: `artisan` file at repo root and `laravel/framework` in `composer.json`.

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

## File length applies normally (300-line cap)

PHP class files commonly drift over 300 lines via wide property/method blocks. Split into traits, value objects, or smaller classes by responsibility before hitting the cap.
