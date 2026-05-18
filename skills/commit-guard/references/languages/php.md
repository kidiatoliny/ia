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

## Pre-push test gate (BLOCKING)

Before any `git push` that includes a tag or merges into the release branch, run the project's full composite test script — typically `composer test` — NOT a filtered subset.

- `--filter` / single-file runs are pre-commit signal only.
- A green `--filter=Foo` run does NOT authorize push.
- Every member script (`test:lint`, `test:refactor`, `test:arch`, `test:types`, `test:type-coverage`, `test:coverage`, `test:typos`, etc.) must pass.
- Test infra failures (cache tagging, missing system binaries like `aspell`, missing coverage driver) count as failures, not "pre-existing infra". Fix them or block the push.

### Pre-existing failure authorization protocol

A failing test may be authorized as "pre-existing, unrelated" only with hard evidence:

1. `git stash` the staged + working changes.
2. Re-run the SAME failing test on the clean tree.
3. Show the user the output — same failure, same line.
4. `git stash pop`.
5. The user explicitly types the authorization phrase (e.g. `authorize: pre-existing failure in <test name>`).

Without those four steps + explicit user phrase, "pre-existing" claims are NOT authorization — they are blockers.

### Refactor sweep rule

When a commit renames or removes a symbol (function, method, property, class), grep the entire repo (`src/`, `tests/`, `database/`, `routes/`, `config/`, any consumer paths) for the old symbol before declaring the refactor done. Missed callers in tests cause delayed CI failures.

Required search command before push when a public API symbol changed:

```
grep -rn "<old-symbol>" --include="*.php" .
```

Zero hits or only doc-comment hits → OK. Live call sites → block until updated.

### Tag-driven release gate

Pushing a release tag (`v*.*.*` or `*.*.*`) implies pre-push gate ran against HEAD AND that HEAD is the same commit being tagged. If commits land between the last `composer test` and the tag, re-run before tagging.

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

## Tests on Laravel projects (MANDATORY)

When project is Laravel:

1. **Pest is mandatory.** New tests MUST be written in Pest (`it('...', function(): void {...});`, `expect()->`, datasets, etc.). PHPUnit `class extends TestCase` style is allowed only for files that already exist in that style — do not introduce new PHPUnit class tests.
2. **No mocks.** Mockery / `$this->mock()` / `partialMock` / `shouldReceive` are LAST RESORT. Prefer:
   - Real Laravel container + database (`RefreshDatabase`).
   - Factories with states (`User::factory()->admin()->create()`).
   - Built-in fakes: `Mail::fake()`, `Queue::fake()`, `Event::fake()`, `Bus::fake()`, `Storage::fake()`, `Http::fake()`, `Notification::fake()`.
   - Test doubles via swapped container bindings (`$this->app->instance(Foo::class, $fake)`) with a plain anonymous class, not a Mockery mock.
3. **When mocks are unavoidable, the staged diff MUST include a comment justifying why a fake/real-call is not viable** (1 line, `// mock: <reason>`).
4. Mockery use in NEW test code without that justification is a BLOCKING violation. Removing/refactoring an existing mock is encouraged and does not require justification.

Detection: grep staged test files for `Mockery::`, `$this->mock(`, `$this->partialMock(`, `shouldReceive(`. Each match must be either:
- pre-existing (unchanged line — `git diff --cached` shows no add for that line),
- accompanied by `// mock:` comment in same hunk, or
- explicitly authorized by user in the current turn.

## Preferred patterns (Laravel)

- **Actions** in `app/Actions/<Domain>/` with single `handle()` method. Stateless `final readonly class`, constructor-injected deps.
- **Builders** for complex object construction or fluent query/composition surfaces. Return `$this` from setters, terminal `build()` / `get()` / specific verb.
- **Pipeline** (`Illuminate\Pipeline\Pipeline`) for staged transformations. Each pipe is a `final class` with `handle($passable, Closure $next)`. Passable should be a Value Object, not the Eloquent model.
- **Value Objects** in `app/ValueObjects/` / `<Pkg>\ValueObjects\`. `final readonly class`, named constructors (`fromArray`, `fromRequest`), immutable, `with*()` returns new instance.

Bad-pattern flags (BLOCKING when new code introduces these instead):

- Fat controller methods doing business logic → must extract into Action.
- Service classes named `*Service` aggregating unrelated methods → split into Actions.
- Mutating Eloquent models inside pipeline pipes → use Value Object passable.
- Anemic arrays passed across domain boundaries → wrap in Value Object.
- Static helper "util" classes (`FooHelper::doX`) → prefer Action or VO method.

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
