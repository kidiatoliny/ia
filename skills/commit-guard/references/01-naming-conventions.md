# Naming Conventions — Per Language

Never invent. Match the community-standard convention for the language. When the project has an explicit override (in its `CLAUDE.md` or established by ≥3 consistent code examples), the project wins.

## Resolution order

1. Project `CLAUDE.md` "Naming" section, if present.
2. ≥3 consistent existing examples in the codebase (infer convention from those).
3. The official community style guide for the language (sources below).
4. If still unclear: ASK the user, citing the source you'd use, before naming anything new.

## Authoritative sources (cite when ambiguous)

| Language        | Authority                                                                 |
|-----------------|---------------------------------------------------------------------------|
| Go              | <https://go.dev/doc/effective_go>, gofmt, Go API guidelines                |
| PHP             | PSR-1 + PSR-12 (<https://www.php-fig.org/psr/>)                           |
| JavaScript      | Airbnb JS Style Guide                                                      |
| TypeScript      | TS Handbook + Microsoft TS Coding Guidelines                               |
| Python          | PEP 8 + PEP 257                                                            |
| Rust            | Rust API Guidelines (<https://rust-lang.github.io/api-guidelines/>)       |
| Ruby            | Ruby Style Guide (<https://rubystyle.guide/>)                              |
| Java            | Google Java Style Guide                                                    |
| Kotlin          | Kotlin Coding Conventions (jetbrains.com)                                  |
| Swift           | Swift API Design Guidelines (swift.org)                                    |
| C#              | .NET Naming Guidelines (Microsoft docs)                                    |
| Elixir          | Elixir Style Guide (christopheradams)                                      |
| Clojure         | Clojure Style Guide (bbatsov)                                              |

## Universal anti-patterns

These are violations regardless of language:

- Abbreviations in identifiers (`cfg`, `usr`, `mgr`) — write `Configuration`, `User`, `Manager`.
- Hungarian notation (`strName`, `iCount`) — strip the prefix.
- Negation in predicates (`isNotValid`) — invert to `isValid` and negate at call site.
- "Helper", "Util", "Manager", "Handler" as the *only* descriptor — name the responsibility instead.
- "Data" suffix on types (`UserData`) — usually the type itself is the data.
- Plural type names for singular entities (`Users` for one user record).
- Stuttered package paths (`shell.ShellCandidates`, `auth.AuthService`).

## Verb-first for functions/methods

Functions perform actions. Name them as imperative verbs:

- `ResolveBinary`, `FindMatches`, `ParseConfig`, `SendNotification`.
- Not `BinaryResolver`, `MatchFinder`, `Parser`, `NotificationSender` (those are *types*).

Predicates return `bool` and start with `is` / `has` / `can` / `should`:

- `isReady`, `hasPermission`, `canExecute`, `shouldRetry`.

## Constructors

Named after what they produce, not the act of producing:

- Go: `NewClient`, `NewCandidates`, or domain-specific like `For(appName)`.
- TS/JS: `createClient`, `new Client()`.
- Python: `Client(...)` or `Client.from_config(...)`.
- Rust: `Client::new(...)`, `Client::from(...)`.

## File names

| Language   | Convention                                                  |
|------------|-------------------------------------------------------------|
| Go         | `lowercase_with_underscores.go`, `<pkg>_test.go`             |
| PHP        | `PascalCase.php` matching class name (PSR-4)                 |
| TS/JS      | Components `PascalCase.tsx`, hooks `useCamelCase.ts`, libs `kebab-case.ts` |
| Python     | `snake_case.py`                                              |
| Rust       | `snake_case.rs`                                              |
| Ruby       | `snake_case.rb`                                              |
| Java       | `PascalCase.java`                                            |

## Folder names

| Language   | Convention                                                |
|------------|-----------------------------------------------------------|
| Go         | `lowercase`, single word, no underscores                  |
| PHP        | `PascalCase` (PSR-4 namespace mapping)                     |
| TS/JS      | `kebab-case` for libs/features; `PascalCase` for component groupings is acceptable but project must be consistent |
| Python     | `snake_case`                                              |
| Rust       | `snake_case`                                              |
| Ruby       | `snake_case`                                              |

## Symbol casing summary

| Symbol               | Go                | PHP                | TS/JS              | Python             | Rust               | Ruby               |
|----------------------|-------------------|--------------------|--------------------|--------------------|--------------------|--------------------|
| Type                 | PascalCase        | PascalCase         | PascalCase         | PascalCase         | PascalCase         | PascalCase         |
| Function/Method      | PascalCase (exported) / camelCase (unexported) | camelCase | camelCase | snake_case | snake_case | snake_case |
| Variable             | camelCase         | camelCase / $snake | camelCase          | snake_case         | snake_case         | snake_case         |
| Constant             | PascalCase / MixedCase | UPPER_SNAKE_CASE | UPPER_SNAKE_CASE  | UPPER_SNAKE_CASE   | UPPER_SNAKE_CASE   | UPPER_SNAKE_CASE   |
| Boolean predicate    | `IsX`/`HasX`      | `isX`              | `isX`              | `is_x`             | `is_x`             | `x?`               |

When a project is mixed across languages, each language uses its own convention.
