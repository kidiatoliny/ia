# Ruby adapter

## Detection

- `Gemfile` present, staged `*.rb` files.

## Required commands

| Stage      | Command                                  |
|------------|------------------------------------------|
| Format     | `rubocop --only Layout`                  |
| Lint       | `rubocop`                                |
| Typecheck  | `srb tc` (if Sorbet) or `steep check` (if Steep) |
| Test       | `rspec` or `bundle exec rspec`           |
| Test (Rails) | `bin/rails test` or `rspec`             |
| Dead code  | `bundle exec debride` if installed, else rubocop's `Lint/UselessAssignment` |

## Naming

Ruby Style Guide (rubystyle.guide).

- Classes/Modules: `PascalCase`.
- Methods/variables: `snake_case`.
- Constants: `UPPER_SNAKE_CASE`.
- Predicates: end with `?` (`valid?`, `present?`).
- Dangerous/destructive methods: end with `!` (`save!`, `reload!`).
- File names: `snake_case.rb`, one class per file matching name.

## Public API surface

- Public methods on classes outside `private/protected` scope.
- Rails: routes, public concerns/services.
- Module functions exposed via `module_function` or constants.

## Test detection

For modified `app/foo/bar.rb`, expect `spec/foo/bar_spec.rb` (RSpec) or `test/foo/bar_test.rb` (Minitest).

## Common bad patterns

- `puts` / `pp` / `p` in source.
- Rescue `Exception` (catches `SystemExit`); use `StandardError` or specific exceptions.
- Reopening core classes (`class String`) without a clear monkey-patch justification.
- `eval`.
- Class-level mutable state.
- Long methods (> 20 lines is suspect, > 50 lines must be split).
- Missing `# frozen_string_literal: true` in new files (Ruby 3+).
- Rails: business logic in controllers (extract to service objects / interactors).

## File length

300-line cap. Rails models commonly drift — extract concerns and service objects.
