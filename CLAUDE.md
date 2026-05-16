# Global Code Standards

## Communication
- Never use emojis in communication or documentation
- Present detailed plans before executing tasks
- Use TodoWrite for multi-step tasks
- Wait for user confirmation before making changes

## Comments — STRICT (applies to ALL languages: PHP, TS/JS, Rust, Go, etc.)
- DO NOT add narrative/explanatory comments. Code must be self-documenting.
- DO NOT add docblocks summarizing what a class/function/file does — names already describe it.
- DO NOT add "why we did this" historical commentary. Use git log/commit messages.
- DO NOT label deprecated/temporary code with verbose paragraphs. One short `// TODO:` line max.
- DO NOT explain obvious code (e.g. `// loop over items`, `// returns the user`, `// Initialize state`).
- DO NOT add section header comments like `// ---- Helpers ----` or `/* ===== Auth ===== */`.
- Allowed:
  - PHPDoc blocks ONLY when required by static analysis (`@var`, `@property`, `@method`, `@param`/`@return` for generics or mixed types).
  - One-line `// TODO:` / `// FIXME:` flags.
  - Short comment (≤1 line) ONLY when the logic is genuinely non-obvious and would mislead an experienced reader.
- When in doubt: NO COMMENT. Delete it.

## PHP
- Use `match` over `switch`, constructor property promotion, explicit return types
- Enums in `app/Enums/`, import classes with `use` (no fully-qualified names)
- Inject services: single-method use → method injection, multi-method use → constructor
- Strict types: `declare(strict_types=1)`, PSR-12, PHPStan max level

## Architecture
- **Actions**: Domain operations in `app/Actions/` with `handle()` method (not `execute()`)
- **Value Objects**: Immutable readonly properties (Email, Money, etc.)
- **Patterns**: Builder, Pipeline, Factory patterns for complex operations
- **Principles**: Single Responsibility, dependency injection, no facades in domain logic

## Validation & Controllers
- **Validation**: Form Request classes only (no inline validation)
- **Controllers**: Route attributes, dependency injection, delegate to Actions
- **Routing**: Spatie Route Attributes (#[Get], #[Post], #[Middleware])
- **Single-method**: `__invoke()`, multi-method: `Route::resource()->only([])`

## API Resources
- Use JsonResource/ResourceCollection (no raw arrays)
- Typed properties, `JsonResource::withoutWrapping()` in AppServiceProvider
- Dedicated Resource class per endpoint

## Models
- Full PHPDoc blocks for PHPStan (attributes, relations, casts)
- Explicit return types for relations (HasMany, BelongsTo, etc.)
- CarbonInterface for dates, proper attribute casting, typed properties only

## Database
- UUIDs: `foreignUuid()` for foreign keys, `HasUuids` trait on models
- Pivot tables: alphabetical order (project_role), use `withTimestamps()` if needed
- Do NOT use `$fillable`. Projects rely on `Model::unguard()` (via nunomaduro/essentials). Skip the array entirely.

## Laravel
- Dev URL: `http://[folder_name].test` (Laravel Herd)
- Observers: `#[ObservedBy([UserObserver::class])]` on models
- Helpers over facades: `auth()->id()` not `Auth::id()`, `redirect()->route()` not `Redirect::route()`
- Eloquent: Use specific fields (`where('id')` not `whereKey()`), skip `::query()` for `create()`
- Enums: Use enum cases/values everywhere (routes, middleware, migrations, UI)

## Laravel 11+ Structure
- **Providers**: AppServiceProvider only (register new ones in `bootstrap/providers.php`)
- **Listeners**: Auto-discover via type-hints
- **Scheduler**: `routes/console.php` (no Kernel.php)
- **Middleware**: Class names in routes, aliases in `bootstrap/app.php`
- **Policies**: Auto-discovered
- **Factories**: Use `fake()` helper

## Frontend (Inertia + React)
- **Inertia**: Lowercase page names, Wayfinder for navigation, pass minimal data
- **Forms**: `useForm` hook or `<Form>` component, Zod validation
- **TypeScript**: Fully typed (no `any`), named exports only (`export function Component()`)
- **State**: Zustand for global state/localStorage, Context for shared data
- **UI**: shadcn/ui or coss.com/origin components
- **Hooks**: Extract reusable logic into custom hooks

## React 19
- **useEffectEvent**: Event handlers with latest props/state (no dependency array needed)
- **Activity**: `<Activity mode="visible|hidden">` preserves state when hidden
- **use**: Unwrap promises/context directly (can be conditional)
- **ref cleanup**: Return cleanup functions from ref callbacks

## Testing (Pest)
- Chain expectations: `expect($a)->toBeTrue()->and($b)->toBeTrue()`
- NO mocks/spies (use real Laravel container & database, fakes for external services)
- Arrange-Act-Assert: meaningful factories (`$adminUser`), specific assertions
- Small focused tests, descriptive names

## React Components
- **Structure**: Smart (logic/state) vs Dumb (UI), <200 lines, single responsibility
- **Hooks**: Extract reusable logic, lazy init, cleanup functions, correct dependencies
- **Performance**: Measure first, memoize sparingly (useMemo/React.memo), lazy load
- **File naming**: PascalCase components, camelCase hooks (useAuth.ts), UPPER_SNAKE_CASE constants
- **Accessibility**: Semantic HTML, ARIA labels, keyboard nav

## Documentation
- Numeric prefixes (00-index.md, 01-usage.md), navigation footer on all pages
- Kebab-case after prefix, numbered index with descriptions

## Git
- Never auto-commit or suggest commits (user decides when)

<laravel-boost-guidelines>
# Laravel Boost (Laravel 12 + Inertia v2 + React 19 + Pest v4 + Tailwind v4)

## Stack
PHP 8.4.12 | Laravel 12 | Inertia v2 | React 19 | Tailwind v4 | Pest v4 | Pint v1 | Larastan v3

## Conventions
- Follow existing code patterns (check sibling files)
- Descriptive names (`isRegisteredForDiscounts` not `discount()`)
- No verification scripts (use tests), no new base folders, no dependency changes without approval
- Frontend changes not visible? Ask user to run `npm run dev` or `composer run dev`
- Only create docs if explicitly requested

## Boost Tools (MCP Server)
- `search-docs`: Version-specific Laravel ecosystem docs (use BEFORE other approaches)
- `list-artisan-commands`: Check Artisan parameters
- `get-absolute-url`: Generate correct URLs
- `tinker`: Execute PHP/query models
- `database-query`: Read from database
- `browser-logs`: Read browser errors (recent only)

## PHP
- Curly braces always, constructor promotion, explicit return types, PHPDoc blocks
- TitleCase enum keys


## Herd
- Site always available at `https?://[kebab-case-project-dir].test` (use `get-absolute-url` tool)

## Inertia
- Components in `resources/js/Pages/`, use `Inertia::render()` for routing
- v2 features: Polling, prefetching, deferred props, infinite scroll, lazy load
- Deferred props: Add skeleton/pulsing empty states
- Forms: `<Form>` component or `useForm` helper (search-docs for details)


## Laravel Best Practices
- `artisan make:` for all files (--no-interaction flag)
- **Database**: Eloquent with relationships + eager loading (avoid N+1), `Model::query()` not `DB::`
- **Models**: Factories + seeders, API Resources for APIs, `casts()` method for casts
- **Validation**: Form Request classes (check sibling files for pattern)
- **Queues**: `ShouldQueue` for long operations
- **Auth**: Built-in gates/policies/Sanctum
- **URLs**: Named routes with `route()` function
- **Config**: `config()` not `env()` (except in config files)
- **Testing**: Factories with states, `php artisan make:test --pest` (mostly feature tests)
- **Vite**: Error? Run `npm run dev` or `composer run dev`

## Laravel 12 Structure
- No middleware files, no Kernel.php, commands auto-register
- `bootstrap/app.php`: middleware/exceptions/routing
- `bootstrap/providers.php`: service providers
- `routes/console.php`: scheduled commands
- Migrations: Include all column attributes when modifying
- Native eager load limit: `$query->latest()->limit(10)`


## Pint
- Run `vendor/bin/pint --dirty` before finalizing (not --test)

## Pest
- Chain expectations: `expect($a)->toBeTrue()->and($b)->toBeTrue()`
- Specific assertions: `assertForbidden()` not `assertStatus(403)`
- NO mocking (use real container/database, fakes for external services)
- Datasets for validation tests
- Run minimal tests: `php artisan test --filter=testName`
- Don't remove test files without approval

## Pest 4 Browser Testing
- `tests/Browser/`, use Laravel features (`Event::fake()`, factories, `RefreshDatabase`)
- Interact: click, type, scroll, submit, drag-drop
- Multi-browser/device testing, light/dark mode, screenshots for debugging

## Inertia + React
- Navigation: `router.visit()` or `<Link>` from `@inertiajs/react`
- Forms: `<Form>` component with render props (errors, processing, wasSuccessful, etc.)

## Tailwind v4
- Use `@import "tailwindcss"` (not `@tailwind` directives)
- No `corePlugins` support
- Follow existing conventions, use `gap` for spacing (not margins), match dark mode patterns
- Deprecated utilities replaced: `bg-opacity-*` → `bg-black/*`, `flex-shrink-*` → `shrink-*`, `overflow-ellipsis` → `text-ellipsis`, etc.

## Test Enforcement
- Every change requires tests (new or updated)
- Run minimal tests: `php artisan test --filter=name`
</laravel-boost-guidelines>