# Global Code Standards

## Communication Style
- NEVER use emojis in any user-facing communication or documentation
- Keep responses clear and professional without decorative elements
- Use plain text formatting only in documentation and guides

## General Code Instructions
- Don't generate code comments above methods or code blocks if they are obvious
- Don't add docblock comments when defining variables, unless instructed to, like `/** @var \App\Models\User $currentUser */`
- Generate comments only for something that needs extra explanation for the reasons why that code was written

## PHP Instructions
- In PHP, use `match` operator over `switch` whenever possible
- Use PHP 8 constructor property promotion. Don't create an empty Constructor method if it doesn't have any parameters
- Using Services in Controllers: if Service class is used only in ONE method of Controller, inject it directly into that method with type-hinting. If Service class is used in MULTIPLE methods of Controller, initialize it in Constructor
- Use return types in functions whenever possible, adding the full path to classname to the top in `use` section
- Generate Enums always in the folder `app/Enums`, not in the main `app/` folder, unless instructed differently
- Import all classes with `use` and reference only their short names; no fully-qualified class names in code

## Architecture & Patterns
- Always use: Action Pattern, Value Objects, Builder Pattern, Pipeline Pattern, and Factory Pattern
- Action Pattern: Every domain operation must be an Action class with a handle() method, stored in app/Actions. Actions must be fully typed
- Value Objects: Use immutable value objects with readonly typed properties for domain-specific fields (Email, Money, PhoneNumber, Coordinates, etc.)
- Builder Pattern: Use builders to construct complex models or DTOs via fluent setters
- Pipeline Pattern: For multi-step transformations, always use Laravel Pipeline with invokable step classes
- Factory Pattern: Use factories for models, DTO creation, service initialization when needed
- Use Wayfinder for navigation
- Apply Single Responsibility Principle everywhere
- Use Inertia response when you have an Inertia app

## Code Quality & Static Analysis
- PHP 8.4 strict types everywhere (`declare(strict_types=1)`)
- PSR-12 compliant
- No unnecessary comments in code except docblocks for static analysis
- Comments only when clarifying complex logic or satisfying static analysis requirements (@var, @property, @method)
- All generated code must be fully compliant with PHPStan max level
- Compatible with Larastan/PHPStan (max level)
- Pass Larastan/PHPStan (level max)

## Actions
- Use Action Pattern for business logic (app/Actions)
- Each Action exposes only one public method: `handle()` (NEVER `execute()`)
- Use dependency injection for all services and actions
- Example:
  ```php
  final readonly class CreateUserAction
  {
      public function __construct(private UserService $service) { }

      public function handle(array $data): User
      {
          return $this->service->create($data);
      }
  }
  ```

## Request Validation
- All input validation must be done using Form Request classes
- No validation logic inside controllers or actions
- Form Requests must include authorize() and rules()
- Always use strict validation rules (uuid, date, numeric, array, email, exists:table,column, unique:table,column, etc.)

## Controllers & Responses
- Controllers should contain ONLY: route attributes, dependency injection, and delegation to actions
- Use Form Requests for validation and authorization
- Use Inertia when you have an Inertia app (Inertia::render)
- Use Resources for output transformation
- Always delegate business logic to Actions

## API Responses & Resources
- Always use Laravel API Resources (JsonResource and ResourceCollection) for output transformation
- Never return raw arrays from controllers or actions
- Resources must use typed properties and follow JSON:API structural conventions
- Disable data wrapper globally: `JsonResource::withoutWrapping()` in AppServiceProvider
- This provides clean responses without "data" key wrapper
- No eager loading inside resources unless explicitly required
- Every endpoint must use a dedicated Resource class

## Routing
- Use Spatie Route Attributes for all HTTP routes
- Controller methods must use attributes such as: #[Get('/users')], #[Post('/users')], #[Put('/users/{id}')], #[Middleware('auth:sanctum')]
- Do not use Route::get() or Route::post() syntax unless absolutely required

## Models
- Every Eloquent Model must include full PHPDoc blocks describing attributes, relations, casts, and return types (to satisfy PHPStan)
- All model properties must use proper PHP attribute casting
- All date attributes must use CarbonInterface cast instead of datetime strings
- Relations must have explicit return types (HasMany, BelongsTo, etc.)
- Cast all model database attributes
- Use type hints on all methods
- No untyped or dynamic properties
- Use docblocks for static analysis (Larastan/PHPStan)

## Database
- Use migration pattern with foreignUuid() for UUID foreign keys
- Use HasUuids trait on models with UUID primary keys
- Use foreignUuid() instead of uuid() for foreign key columns
- For DB pivot tables, use correct alphabetical order, like "project_role" instead of "role_project"
- When creating pivot tables in migrations, if you use `timestamps()`, then in Eloquent Models, add `withTimestamps()` to the `BelongsToMany` relationships
- When adding columns in a migration, update the model's `$fillable` array to include those new attributes

## Laravel Instructions
- Local development: always assume that the main URL of the project is `http://[folder_name].test` (using Laravel Herd)
- Eloquent Observers: should be registered in Eloquent Models with PHP Attributes, and not in AppServiceProvider. Example: `#[ObservedBy([UserObserver::class])]` with `use Illuminate\Database\Eloquent\Attributes\ObservedBy;` on top
- When generating Controllers, put validation in Form Request classes and use `$request->validated()` instead of listing inputs one by one
- Aim for "slim" Controllers and put larger logic pieces in Service classes
- Use Laravel helpers instead of `use` section classes whenever possible. Examples: use `auth()->id()` instead of `Auth::id()` and adding `Auth` in the `use` section. Another example: use `redirect()->route()` instead of `Redirect::route()`
- Don't use `whereKey()` or `whereKeyNot()`, use specific fields like `id`. Example: instead of `->whereKeyNot($currentUser->getKey())`, use `->where('id', '!=', $currentUser->id)`
- Don't add `::query()` when running Eloquent `create()` statements. Example: instead of `User::query()->create()`, use `User::create()`
- In Livewire projects, don't use Livewire Volt. Only Livewire class components
- Enums: If a PHP Enum exists for a domain concept, always use its cases (or their `->value`) instead of raw strings everywhere — routes, middleware, migrations, seeds, configs, and UI defaults
- Controllers: Single-method Controllers should use `__invoke()`; multi-method RESTful controllers should use `Route::resource()->only([])`

## Laravel 11+ Skeleton Structure
- **Service Providers**: there are no other service providers except AppServiceProvider. Don't create new service providers unless absolutely necessary. Use Laravel 11+ new features, instead. Or, if you really need to create a new service provider, register it in `bootstrap/providers.php` and not `config/app.php` like it used to be before Laravel 11
- **Event Listeners**: since Laravel 11, Listeners auto-listen for the events if they are type-hinted correctly
- **Console Scheduler**: scheduled commands should be in `routes/console.php` and not `app/Console/Kernel.php` which doesn't exist since Laravel 11
- **Middleware**: whenever possible, use Middleware by class name in the routes. But if you do need to register Middleware alias, it should be registered in `bootstrap/app.php` and not `app/Http/Kernel.php` which doesn't exist since Laravel 11
- **Tailwind**: in new Blade pages, use Tailwind and not Bootstrap, unless instructed otherwise in the prompt. Tailwind is already pre-configured since Laravel 11, with Vite
- **Faker**: in Factories, use `fake()` helper instead of `$this->faker`
- **Policies**: Laravel automatically auto-discovers Policies, no need to register them in the Service Providers

## Frontend
- Use Wayfinder for route generation and navigation
- Use Inertia for server-side rendering with React
- Pass only necessary data from controllers
- Inertia page names must be lowercase (e.g., `Inertia::render('dashboard', $data)`)
- Page component files match route names and are auto-loaded by Vite

## Inertia Best Practices
- **Form Validation**: All form validation must be done using Zod schemas on the frontend
- **Forms**: Always use `useForm` hook from Inertia or the Form Component from Inertia
- **LocalStorage**: Use Zustand for local storage needs instead of raw localStorage API
- **Routing**: Always use Wayfinder for route generation and navigation
- **TypeScript**: Everything must be fully typed with TypeScript - no `any` types
- **Code Comments**: Do not comment code unless absolutely necessary for complex logic explanation
- **Custom Hooks**: Extract reusable logic into custom hooks whenever it promotes code reuse
- **UI Components**: Use shadcn/ui components or components from https://coss.com/origin for UI elements
- **Named Exports**: Never use `export default` for components - always use named exports like `export function ComponentName()`

## React 19 Best Practices
- **useEffectEvent Hook**: Use `useEffectEvent` for event handlers that need to access latest props/state without triggering effects
  - Functions wrapped with useEffectEvent don't need to be in dependency arrays
  - Always use the latest values without re-running effects
  - Example:
    ```tsx
    import { useEffect, useEffectEvent } from 'react';
    
    const onCommandChange = useEffectEvent(() => {
      console.log(commands); // Always latest without deps
    });
    
    useEffect(() => {
      onCommandChange();
    }, [commandIndex]); // commands not needed in deps!
    ```
- **Activity Component**: Use `<Activity>` for conditional rendering that preserves component state when hidden
  - Replace `{condition && <Component />}` with `<Activity mode={condition ? "visible" : "hidden"}>`
  - State is preserved when toggling visibility
  - Example:
    ```tsx
    import { Activity } from 'react';
    
    <Activity mode={isVisible ? "visible" : "hidden"}>
      <Sidebar /> {/* State preserved when hidden */}
    </Activity>
    ```
- **use Hook**: Use `use()` hook to unwrap promises and context directly in components
  - Works with promises, context, and async resources
  - Can be used conditionally unlike other hooks
  - Example:
    ```tsx
    import { use } from 'react';
    
    function UserData({ userPromise }) {
      const user = use(userPromise); // Unwrap promise
      return <div>{user.name}</div>;
    }
    ```
- **ref Callback Cleanup**: Return cleanup functions from ref callbacks for proper cleanup
  - Example:
    ```tsx
    <div ref={(node) => {
      // Setup
      node?.addEventListener('scroll', handleScroll);
      
      // Cleanup
      return () => node?.removeEventListener('scroll', handleScroll);
    }} />
    ```

## Testing
- Use Pest and not PHPUnit. Run tests with `php artisan test`
- When writing Pest tests, always use expectation chains with `->and()` instead of multiple expect() calls
  - Bad: `expect($a)->toBeTrue(); expect($b)->toBeTrue();`
  - Good: `expect($a)->toBeTrue()->and($b)->toBeTrue();`
- **Use Pest framework exclusively**
- **Use chaining expect() for all assertions**
- **Use the real Laravel container** - no container mocking
- **Use real database interactions** - leverage Laravel's testing database features
- **Use fake implementations via contracts** when external services are involved
- **Strictly Prohibited:**
  - ❌ NO mocks - do not use Mockery or any mocking framework
  - ❌ NO spies - do not spy on method calls
  - ❌ NO large end-to-end job tests - keep tests small and focused
- **Preferred Testing Style:**
  - ✅ Write many small tests
  - ✅ Ensure clear intent per test
  - ✅ Keep minimal setup
  - ✅ One assertion concept per test
  - ✅ Use descriptive test names
- Every test method should be structured with Arrange-Act-Assert
  - **Arrange phase**: use Laravel factories but add meaningful column values and variable names if they help to understand failed tests better
    - Bad example: `$user1 = User::factory()->create();`
    - Better example: `$adminUser = User::factory()->create(['email' => 'admin@admin.com']);`
  - **Act phase**: perform the action being tested
  - **Assert phase**: perform assertions when applicable:
    - HTTP status code returned from Act: `assertStatus()`
    - Structure/data returned from Act (Blade or JSON): functions like `assertViewHas()`, `assertSee()`, `assertDontSee()` or `assertJsonContains()`
    - Redirect assertions like `assertRedirect()` and `assertSessionHas()` in case of Flash session values passed
    - DB changes if any create/update/delete operation was performed: functions like `assertDatabaseHas()`, `assertDatabaseMissing()`, `expect($variable)->toBe()` and similar

## Broadcasting (Laravel Echo & Reverb)
- Use Laravel Echo for real-time event broadcasting
- Configure broadcasting driver in `config/broadcasting.php`
- Implement broadcast events using `ShouldBroadcast` interface
- Broadcast events from Actions or Services for business logic separation
- Use channel authorization in `routes/channels.php` for private/presence channels
- Configure Reverb connection with proper environment variables (REVERB_APP_KEY, REVERB_APP_SECRET, etc.)
- Always validate user authorization before broadcasting sensitive data
- Use proper queue configuration for broadcasting jobs

## General Coding Rules
- Use strict typing everywhere: declare(strict_types=1)
- Use readonly properties and classes where possible
- No facades inside domain logic; use dependency injection
- Business logic must always be inside Actions, Value Objects, Pipelines, or Builders
- Responses must always be returned through Resources
- No validation logic inside controllers or actions (use Form Requests)
- No untyped properties or methods
- Dependencies must be injected via constructor, never retrieved via Service Locator
- Services should be focused and follow Single Responsibility Principle

## Filament v4
- Validation rule `unique()` has `ignoreRecord: true` by default, no need to specify it
- Don't use full namespaces when referencing Filament classes like `Filament\Forms\Components\DatePicker`. Always put the namespaces in `use` section on top and use only classname instead of full path
- If you create custom Blade files with Tailwind classes, you need to create a custom theme and specify the folder of those Blade files in theme.css
- Table Filters have `->schema()` instead of `->form()`
- `Action::make()` has `->schema()` instead of `->form()`
- Table has `->toolbarActions()` instead of `->bulkActions()`

## Git & Commits
- NEVER ask permission to make commits
- NEVER automatically create commits
- User will make their own commits when they consider it necessary
- Do not suggest or offer to commit changes
## React Component Guidelines

### Single Responsibility Principle
- Each component should have one clear purpose and do it well
- If a component has multiple concerns, split it into smaller components
- Component names should clearly indicate their single responsibility
- Keep components under 200 lines of code

### Component Organization
- Container Components (Smart): Handle logic, state, and data fetching
- Presentation Components (Dumb): Focus only on UI rendering
- Layout Components: Manage page structure and composition
- Feature Components: Group related functionality in feature folders

### Always Use Custom Hooks When
- Logic is reused across multiple components
- State management is complex or shared
- Side effects need to be isolated and tested
- API calls or data fetching is needed
- Browser APIs are accessed (localStorage, geolocation, etc.)

### Hook Best Practices
- Use lazy initialization for expensive computations in useState
- Keep useEffect focused on one concern
- Always return cleanup functions when needed
- List all dependencies correctly
- Only use useMemo/useCallback when performance issues are measured

### Component Composition
- Always define clear TypeScript interfaces for props
- Avoid prop drilling - use Context or state management (Zustand)
- Pass data down via props, events up via callbacks
- Use Zustand for complex shared state

### TypeScript Standards
- Always type props, state, and return values
- Use interfaces for object shapes
- Avoid any type - use unknown if needed
- Leverage type inference when obvious

### File Naming & Structure
- Components: PascalCase (UserProfile.tsx)
- Hooks: camelCase with "use" prefix (useAuth.ts)
- Utils/Helpers: camelCase (formatDate.ts)
- Constants: UPPER_SNAKE_CASE (API_BASE_URL)
- One component per file
- Use barrel exports (index.ts) for feature folders

### Performance Optimization
- Measure first with React DevTools Profiler
- Memoize expensive calculations with useMemo
- Use React.memo for components that re-render frequently
- Lazy load heavy components with React.lazy
- Debounce expensive operations

### State Management
- Local State (useState/useReducer): Component-specific state, form inputs, UI toggles
- Global State (Zustand): User auth, app settings, shared data across routes
- Server State (React Query/SWR): API data, cache management

### Accessibility
- Use semantic HTML elements
- Include ARIA labels when needed
- Support keyboard navigation
- Manage focus properly
- Ensure screen reader compatibility

## Documentation Structure

### Markdown Files Naming & Organization
- **Numeric Prefixes**: All documentation files must use numeric prefixes (00-, 01-, 02-, etc.)
  - Example: `00-index.md`, `01-usage.md`, `02-installation.md`
  - This provides natural ordering and makes navigation clear

- **Navigation Between Pages**: Every documentation page (except the index) must include navigation footer
  - Format at the end of each file:
    ```
    ---

    **← Previous:** [XX - Page Title](./XX-filename.md) | **Next:** [YY - Next Page →](./YY-next.md)
    ```
  - The index page should have:
    ```
    ---

    **Next:** [01 - Next Page →](./01-filename.md)
    ```

- **Documentation Index**: The main index (00-index.md) should contain a numbered list of all documentation pages
  - Link format: `[NN - Page Title](./NN-filename.md) - Brief description`

- **File Naming**: Use descriptive kebab-case names after the prefix
  - Good: `02-pdf-generators.md`, `03-builders.md`
  - Bad: `02-pdf.md`, `03-b.md`

- **Cross-References**: When linking to documentation files in README or other places, always use the full filename with numeric prefix
  - Example: `[PDF Generators Guide](docs/02-pdf-generators.md)`

<laravel-boost-guidelines>
=== foundation rules ===

# Laravel Boost Guidelines

The Laravel Boost guidelines are specifically curated by Laravel maintainers for this application. These guidelines should be followed closely to enhance the user's satisfaction building Laravel applications.

## Foundational Context
This application is a Laravel application and its main Laravel ecosystems package & versions are below. You are an expert with them all. Ensure you abide by these specific packages & versions.

- php - 8.4.12
- inertiajs/inertia-laravel (INERTIA) - v2
- laravel/framework (LARAVEL) - v12
- laravel/prompts (PROMPTS) - v0
- laravel/scout (SCOUT) - v10
- laravel/wayfinder (WAYFINDER) - v0
- larastan/larastan (LARASTAN) - v3
- laravel/pint (PINT) - v1
- laravel/sail (SAIL) - v1
- pestphp/pest (PEST) - v4
- phpunit/phpunit (PHPUNIT) - v12
- rector/rector (RECTOR) - v2
- @inertiajs/react (INERTIA) - v2
- react (REACT) - v19
- tailwindcss (TAILWINDCSS) - v4
- @laravel/vite-plugin-wayfinder (WAYFINDER) - v0
- eslint (ESLINT) - v9
- prettier (PRETTIER) - v3


## Conventions
- You must follow all existing code conventions used in this application. When creating or editing a file, check sibling files for the correct structure, approach, naming.
- Use descriptive names for variables and methods. For example, `isRegisteredForDiscounts`, not `discount()`.
- Check for existing components to reuse before writing a new one.

## Verification Scripts
- Do not create verification scripts or tinker when tests cover that functionality and prove it works. Unit and feature tests are more important.

## Application Structure & Architecture
- Stick to existing directory structure - don't create new base folders without approval.
- Do not change the application's dependencies without approval.

## Frontend Bundling
- If the user doesn't see a frontend change reflected in the UI, it could mean they need to run `npm run build`, `npm run dev`, or `composer run dev`. Ask them.

## Replies
- Be concise in your explanations - focus on what's important rather than explaining obvious details.

## Documentation Files
- You must only create documentation files if explicitly requested by the user.


=== boost rules ===

## Laravel Boost
- Laravel Boost is an MCP server that comes with powerful tools designed specifically for this application. Use them.

## Artisan
- Use the `list-artisan-commands` tool when you need to call an Artisan command to double check the available parameters.

## URLs
- Whenever you share a project URL with the user you should use the `get-absolute-url` tool to ensure you're using the correct scheme, domain / IP, and port.

## Tinker / Debugging
- You should use the `tinker` tool when you need to execute PHP to debug code or query Eloquent models directly.
- Use the `database-query` tool when you only need to read from the database.

## Reading Browser Logs With the `browser-logs` Tool
- You can read browser logs, errors, and exceptions using the `browser-logs` tool from Boost.
- Only recent browser logs will be useful - ignore old logs.

## Searching Documentation (Critically Important)
- Boost comes with a powerful `search-docs` tool you should use before any other approaches. This tool automatically passes a list of installed packages and their versions to the remote Boost API, so it returns only version-specific documentation specific for the user's circumstance. You should pass an array of packages to filter on if you know you need docs for particular packages.
- The 'search-docs' tool is perfect for all Laravel related packages, including Laravel, Inertia, Livewire, Filament, Tailwind, Pest, Nova, Nightwatch, etc.
- You must use this tool to search for Laravel-ecosystem documentation before falling back to other approaches.
- Search the documentation before making code changes to ensure we are taking the correct approach.
- Use multiple, broad, simple, topic based queries to start. For example: `['rate limiting', 'routing rate limiting', 'routing']`.
- Do not add package names to queries - package information is already shared. For example, use `test resource table`, not `filament 4 test resource table`.

### Available Search Syntax
- You can and should pass multiple queries at once. The most relevant results will be returned first.

1. Simple Word Searches with auto-stemming - query=authentication - finds 'authenticate' and 'auth'
2. Multiple Words (AND Logic) - query=rate limit - finds knowledge containing both "rate" AND "limit"
3. Quoted Phrases (Exact Position) - query="infinite scroll" - Words must be adjacent and in that order
4. Mixed Queries - query=middleware "rate limit" - "middleware" AND exact phrase "rate limit"
5. Multiple Queries - queries=["authentication", "middleware"] - ANY of these terms


=== php rules ===

## PHP

- Always use curly braces for control structures, even if it has one line.

### Constructors
- Use PHP 8 constructor property promotion in `__construct()`.
    - <code-snippet>public function __construct(public GitHub $github) { }</code-snippet>
- Do not allow empty `__construct()` methods with zero parameters.

### Type Declarations
- Always use explicit return type declarations for methods and functions.
- Use appropriate PHP type hints for method parameters.

<code-snippet name="Explicit Return Types and Method Params" lang="php">
protected function isAccessible(User $user, ?string $path = null): bool
{
    ...
}
</code-snippet>

## Comments
- Prefer PHPDoc blocks over comments. Never use comments within the code itself unless there is something _very_ complex going on.

## PHPDoc Blocks
- Add useful array shape type definitions for arrays when appropriate.

## Enums
- Typically, keys in an Enum should be TitleCase. For example: `FavoritePerson`, `BestLake`, `Monthly`.


=== herd rules ===

## Laravel Herd

- The application is served by Laravel Herd and will be available at: https?://[kebab-case-project-dir].test. Use the `get-absolute-url` tool to generate URLs for the user to ensure valid URLs.
- You must not run any commands to make the site available via HTTP(s). It is _always_ available through Laravel Herd.


=== inertia-laravel/core rules ===

## Inertia Core

- Inertia.js components should be placed in the `resources/js/Pages` directory unless specified differently in the JS bundler (vite.config.js).
- Use `Inertia::render()` for server-side routing instead of traditional Blade views.
- Use `search-docs` for accurate guidance on all things Inertia.

<code-snippet lang="php" name="Inertia::render Example">
// routes/web.php example
Route::get('/users', function () {
    return Inertia::render('Users/Index', [
        'users' => User::all()
    ]);
});
</code-snippet>


=== inertia-laravel/v2 rules ===

## Inertia v2

- Make use of all Inertia features from v1 & v2. Check the documentation before making any changes to ensure we are taking the correct approach.

### Inertia v2 New Features
- Polling
- Prefetching
- Deferred props
- Infinite scrolling using merging props and `WhenVisible`
- Lazy loading data on scroll

### Deferred Props & Empty States
- When using deferred props on the frontend, you should add a nice empty state with pulsing / animated skeleton.

### Inertia Form General Guidance
- The recommended way to build forms when using Inertia is with the `<Form>` component - a useful example is below. Use `search-docs` with a query of `form component` for guidance.
- Forms can also be built using the `useForm` helper for more programmatic control, or to follow existing conventions. Use `search-docs` with a query of `useForm helper` for guidance.
- `resetOnError`, `resetOnSuccess`, and `setDefaultsOnSuccess` are available on the `<Form>` component. Use `search-docs` with a query of 'form component resetting' for guidance.


=== laravel/core rules ===

## Do Things the Laravel Way

- Use `php artisan make:` commands to create new files (i.e. migrations, controllers, models, etc.). You can list available Artisan commands using the `list-artisan-commands` tool.
- If you're creating a generic PHP class, use `artisan make:class`.
- Pass `--no-interaction` to all Artisan commands to ensure they work without user input. You should also pass the correct `--options` to ensure correct behavior.

### Database
- Always use proper Eloquent relationship methods with return type hints. Prefer relationship methods over raw queries or manual joins.
- Use Eloquent models and relationships before suggesting raw database queries
- Avoid `DB::`; prefer `Model::query()`. Generate code that leverages Laravel's ORM capabilities rather than bypassing them.
- Generate code that prevents N+1 query problems by using eager loading.
- Use Laravel's query builder for very complex database operations.

### Model Creation
- When creating new models, create useful factories and seeders for them too. Ask the user if they need any other things, using `list-artisan-commands` to check the available options to `php artisan make:model`.

### APIs & Eloquent Resources
- For APIs, default to using Eloquent API Resources and API versioning unless existing API routes do not, then you should follow existing application convention.

### Controllers & Validation
- Always create Form Request classes for validation rather than inline validation in controllers. Include both validation rules and custom error messages.
- Check sibling Form Requests to see if the application uses array or string based validation rules.

### Queues
- Use queued jobs for time-consuming operations with the `ShouldQueue` interface.

### Authentication & Authorization
- Use Laravel's built-in authentication and authorization features (gates, policies, Sanctum, etc.).

### URL Generation
- When generating links to other pages, prefer named routes and the `route()` function.

### Configuration
- Use environment variables only in configuration files - never use the `env()` function directly outside of config files. Always use `config('app.name')`, not `env('APP_NAME')`.

### Testing
- When creating models for tests, use the factories for the models. Check if the factory has custom states that can be used before manually setting up the model.
- Faker: Use methods such as `$this->faker->word()` or `fake()->randomDigit()`. Follow existing conventions whether to use `$this->faker` or `fake()`.
- When creating tests, make use of `php artisan make:test [options] <name>` to create a feature test, and pass `--unit` to create a unit test. Most tests should be feature tests.

### Vite Error
- If you receive an "Illuminate\Foundation\ViteException: Unable to locate file in Vite manifest" error, you can run `npm run build` or ask the user to run `npm run dev` or `composer run dev`.


=== laravel/v12 rules ===

## Laravel 12

- Use the `search-docs` tool to get version specific documentation.
- Since Laravel 11, Laravel has a new streamlined file structure which this project uses.

### Laravel 12 Structure
- No middleware files in `app/Http/Middleware/`.
- `bootstrap/app.php` is the file to register middleware, exceptions, and routing files.
- `bootstrap/providers.php` contains application specific service providers.
- **No app\Console\Kernel.php** - use `bootstrap/app.php` or `routes/console.php` for console configuration.
- **Commands auto-register** - files in `app/Console/Commands/` are automatically available and do not require manual registration.

### Database
- When modifying a column, the migration must include all of the attributes that were previously defined on the column. Otherwise, they will be dropped and lost.
- Laravel 11 allows limiting eagerly loaded records natively, without external packages: `$query->latest()->limit(10);`.

### Models
- Casts can and likely should be set in a `casts()` method on a model rather than the `$casts` property. Follow existing conventions from other models.


=== pint/core rules ===

## Laravel Pint Code Formatter

- You must run `vendor/bin/pint --dirty` before finalizing changes to ensure your code matches the project's expected style.
- Do not run `vendor/bin/pint --test`, simply run `vendor/bin/pint` to fix any formatting issues.


=== pest/core rules ===

## Pest

### Testing
- If you need to verify a feature is working, write or update a Unit / Feature test.

### Pest Expectations
- Always use expectation chains with `->and()` instead of multiple expect() calls
- Bad: `expect($a)->toBeTrue(); expect($b)->toBeTrue();`
- Good: `expect($a)->toBeTrue()->and($b)->toBeTrue();`

### Pest Tests
- All tests must be written using Pest. Use `php artisan make:test --pest <name>`.
- You must not remove any tests or test files from the tests directory without approval. These are not temporary or helper files - these are core to the application.
- Tests should test all of the happy paths, failure paths, and weird paths.
- Tests live in the `tests/Feature` and `tests/Unit` directories.
- Pest tests look and behave like this:
<code-snippet name="Basic Pest Test Example" lang="php">
it('is true', function () {
    expect(true)->toBeTrue();
});
</code-snippet>

### Running Tests
- Run the minimal number of tests using an appropriate filter before finalizing code edits.
- To run all tests: `php artisan test`.
- To run all tests in a file: `php artisan test tests/Feature/ExampleTest.php`.
- To filter on a particular test name: `php artisan test --filter=testName` (recommended after making a change to a related file).
- When the tests relating to your changes are passing, ask the user if they would like to run the entire test suite to ensure everything is still passing.

### Pest Assertions
- When asserting status codes on a response, use the specific method like `assertForbidden` and `assertNotFound` instead of using `assertStatus(403)` or similar, e.g.:
<code-snippet name="Pest Example Asserting postJson Response" lang="php">
it('returns all', function () {
    $response = $this->postJson('/api/docs', []);

    $response->assertSuccessful();
});
</code-snippet>

### Mocking
- **Avoid mocking whenever possible** - use real implementations and Laravel's container to resolve dependencies.
- Only use mocking for external services or when absolutely necessary (e.g., third-party APIs, payment gateways).
- When you must mock, use the `Pest\Laravel\mock` Pest function, but always import it via `use function Pest\Laravel\mock;` before using it. Alternatively, you can use `$this->mock()` if existing tests do.
- Use Laravel's container (`app()`, `resolve()`) to instantiate classes in tests rather than mocking internal dependencies.

### Datasets
- Use datasets in Pest to simplify tests which have a lot of duplicated data. This is often the case when testing validation rules, so consider going with this solution when writing tests for validation rules.

<code-snippet name="Pest Dataset Example" lang="php">
it('has emails', function (string $email) {
    expect($email)->not->toBeEmpty();
})->with([
    'james' => 'james@laravel.com',
    'taylor' => 'taylor@laravel.com',
]);
</code-snippet>


=== pest/v4 rules ===

## Pest 4

- Pest v4 is a huge upgrade to Pest and offers: browser testing, smoke testing, visual regression testing, test sharding, and faster type coverage.
- Browser testing is incredibly powerful and useful for this project.
- Browser tests should live in `tests/Browser/`.
- Use the `search-docs` tool for detailed guidance on utilizing these features.

### Browser Testing
- You can use Laravel features like `Event::fake()`, `assertAuthenticated()`, and model factories within Pest v4 browser tests, as well as `RefreshDatabase` (when needed) to ensure a clean state for each test.
- Interact with the page (click, type, scroll, select, submit, drag-and-drop, touch gestures, etc.) when appropriate to complete the test.
- If requested, test on multiple browsers (Chrome, Firefox, Safari).
- If requested, test on different devices and viewports (like iPhone 14 Pro, tablets, or custom breakpoints).
- Switch color schemes (light/dark mode) when appropriate.
- Take screenshots or pause tests for debugging when appropriate.

### Example Tests

<code-snippet name="Pest Browser Test Example" lang="php">
it('may reset the password', function () {
    Notification::fake();

    $this->actingAs(User::factory()->create());

    $page = visit('/sign-in'); // Visit on a real browser...

    $page->assertSee('Sign In')
        ->assertNoJavascriptErrors() // or ->assertNoConsoleLogs()
        ->click('Forgot Password?')
        ->fill('email', 'nuno@laravel.com')
        ->click('Send Reset Link')
        ->assertSee('We have emailed your password reset link!')

    Notification::assertSent(ResetPassword::class);
});
</code-snippet>

<code-snippet name="Pest Smoke Testing Example" lang="php">
$pages = visit(['/', '/about', '/contact']);

$pages->assertNoJavascriptErrors()->assertNoConsoleLogs();
</code-snippet>


=== inertia-react/core rules ===

## Inertia + React

- Use `router.visit()` or `<Link>` for navigation instead of traditional links.

<code-snippet name="Inertia Client Navigation" lang="react">

import { Link } from '@inertiajs/react'
<Link href="/">Home</Link>

</code-snippet>


=== inertia-react/v2/forms rules ===

## Inertia + React Forms

<code-snippet name="`<Form>` Component Example" lang="react">

import { Form } from '@inertiajs/react'

export default () => (
    <Form action="/users" method="post">
        {({
            errors,
            hasErrors,
            processing,
            wasSuccessful,
            recentlySuccessful,
            clearErrors,
            resetAndClearErrors,
            defaults
        }) => (
        <>
        <input type="text" name="name" />

        {errors.name && <div>{errors.name}</div>}

        <button type="submit" disabled={processing}>
            {processing ? 'Creating...' : 'Create User'}
        </button>

        {wasSuccessful && <div>User created successfully!</div>}
        </>
    )}
    </Form>
)

</code-snippet>


=== tailwindcss/core rules ===

## Tailwind Core

- Use Tailwind CSS classes to style HTML, check and use existing tailwind conventions within the project before writing your own.
- Offer to extract repeated patterns into components that match the project's conventions (i.e. Blade, JSX, Vue, etc..)
- Think through class placement, order, priority, and defaults - remove redundant classes, add classes to parent or child carefully to limit repetition, group elements logically
- You can use the `search-docs` tool to get exact examples from the official documentation when needed.

### Spacing
- When listing items, use gap utilities for spacing, don't use margins.

    <code-snippet name="Valid Flex Gap Spacing Example" lang="html">
        <div class="flex gap-8">
            <div>Superior</div>
            <div>Michigan</div>
            <div>Erie</div>
        </div>
    </code-snippet>


### Dark Mode
- If existing pages and components support dark mode, new pages and components must support dark mode in a similar way, typically using `dark:`.


=== tailwindcss/v4 rules ===

## Tailwind 4

- Always use Tailwind CSS v4 - do not use the deprecated utilities.
- `corePlugins` is not supported in Tailwind v4.
- In Tailwind v4, you import Tailwind using a regular CSS `@import` statement, not using the `@tailwind` directives used in v3:

<code-snippet name="Tailwind v4 Import Tailwind Diff" lang="diff"
   - @tailwind base;
   - @tailwind components;
   - @tailwind utilities;
   + @import "tailwindcss";
</code-snippet>


### Replaced Utilities
- Tailwind v4 removed deprecated utilities. Do not use the deprecated option - use the replacement.
- Opacity values are still numeric.

| Deprecated |	Replacement |
|------------+--------------|
| bg-opacity-* | bg-black/* |
| text-opacity-* | text-black/* |
| border-opacity-* | border-black/* |
| divide-opacity-* | divide-black/* |
| ring-opacity-* | ring-black/* |
| placeholder-opacity-* | placeholder-black/* |
| flex-shrink-* | shrink-* |
| flex-grow-* | grow-* |
| overflow-ellipsis | text-ellipsis |
| decoration-slice | box-decoration-slice |
| decoration-clone | box-decoration-clone |


=== tests rules ===

## Test Enforcement

- Every change must be programmatically tested. Write a new test or update an existing test, then run the affected tests to make sure they pass.
- Run the minimum number of tests needed to ensure code quality and speed. Use `php artisan test` with a specific filename or filter.
</laravel-boost-guidelines>