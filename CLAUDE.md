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

## Testing
- Use Pest and not PHPUnit. Run tests with `php artisan test`
- When writing Pest tests, always use expectation chains with `->and()` instead of multiple expect() calls
  - Bad: `expect($a)->toBeTrue(); expect($b)->toBeTrue();`
  - Good: `expect($a)->toBeTrue()->and($b)->toBeTrue();`
- **Never use mocks** - use real implementations or Laravel's container to resolve dependencies
  - Bad: `$mock = Mockery::mock(Service::class)`
  - Good: `app(Service::class)` or inject via constructor
- **Use Laravel Container** for dependency resolution instead of manually instantiating classes
  - Example: `$service = app(MyService::class);` or use dependency injection in test methods
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

