# Comments Policy — Strict (zero tolerance)

Code is self-documenting. Documentation lives in `docs/`. Comments inside source files are forbidden by default.

This policy is **stricter than community defaults** for every language. GoDoc / TSDoc / PHPDoc conventions that push "every public symbol gets a doc comment" do NOT apply here.

## Banned (always)

- **Any `//` or `#` comment** that restates the function / type / class / variable name. If the name doesn't explain it, fix the name.
- **Package-level / file-level summary comments** (`// Package x provides ...`, `// This file ...`). The package name is in the path; the file purpose is in the function it contains. Doc lives in `docs/`.
- **GoDoc / TSDoc / PHPDoc on exported symbols** when the docstring just paraphrases the signature. The signature is the documentation.
- **Narrative comments** explaining what the code does line-by-line.
- **Historical commentary** ("we used to do X but switched to Y because Z"). Use `git log` and commit messages.
- **Deprecated/temporary verbose paragraphs**. One short `// TODO(@handle):` line max.
- **Obvious-code comments**: `// loop over items`, `// returns the user`, `// initialize state`.
- **Section header comments**: `// ---- Helpers ----`, `/* ===== Auth ===== */`, `// region Foo / endregion`.
- **Commented-out code**. Delete it. Git remembers.
- **Banner comments** with ASCII art or decorative borders.
- **AI-generated explanation drift**: long-form essays about why a one-liner exists.

## Allowed (narrow exceptions)

1. **Static analysis annotations** that the toolchain requires to type-check:
   - PHP: `@var`, `@property`, `@method`, `@param`/`@return` (and `@template`, `@extends`, `@implements`, `@mixin`, `@throws`, `@phpstan-*`, `@psalm-*`) ONLY when PHPStan / Psalm cannot infer. The scanner auto-allows a `/** */` block whose every content line is one of these tags; a block mixing narrative prose with tags is still flagged.
   - TypeScript: TSDoc ONLY when a generic type parameter can't be inferred by the language server.
   - Rust: `#[doc = "..."]` only where `cargo doc` is shipped externally and the doc is non-obvious.
   - Go: GoDoc is **not** required. `golint` warnings about missing package comments and exported-symbol comments are tolerated; lint configs should silence them if the linter complains.
   - Python: type hints; docstrings only on public functions that have non-obvious invariants (PEP 257 one-liner max).
2. **One-line `// TODO(@handle):` / `// FIXME(@handle):`** flags. Handle is required so blame is clear.
3. **≤1-line non-obvious-logic note** when an experienced reader would misread the code without it:
   ```go
   bits := math.Float64bits(f) // bitcast: IEEE 754 reinterpret, not a numeric convert
   ```
   Note explains a non-obvious mechanism in one line. Must add information the code can't.
4. **License headers** required by the project (SPDX format preferred).
5. **Tool directives** masquerading as comments: `@ts-expect-error`, `// eslint-disable-next-line <rule>`, `//go:build ...`, `// +build`, `# noqa: E501`. These are not comments; they are pragmas.

## Cross-language summary

| Language | Convention says | This project says |
|----------|-----------------|-------------------|
| Go | `// Package x ...` + `// Func ...` on every export | NO. Skip unless behaviour is non-obvious. Silence `golint` warnings. |
| TS/JS | TSDoc on exported functions | NO. Skip. Use TSDoc only when a generic can't be inferred. |
| PHP | PHPDoc with `@param`/`@return` | NO. Use only when PHPStan needs it. |
| Rust | `///` on every `pub` item | NO. Skip unless non-obvious. |
| Python | Docstring per public function | NO. One-line only for non-obvious invariants. |

## Detection patterns to flag (BLOCK)

The skill blocks any of these in the staged diff:

- Any `//` or `#` comment on the line immediately above a function / type / const declaration whose text contains the symbol's identifier as English prose ("Foo does X", "Bar returns Y", "Baz is the canonical Z").
- Any `// Package <name> ...` or `// Module <name> ...` line at the top of a file.
- Any multi-line `/* */` block that isn't a license header.
- Any `//` line longer than 100 chars (likely narrative).
- Any comment containing AI-tell phrases ("This function is responsible for...", "Here we...", "The purpose of this code...", "responsible for", "in charge of").
- Section dividers (regex: `^//\s*[-=*]{3,}` or `^//\s*region\b`).
- Commented-out code (heuristic: comment lines that parse as valid code in the file's language).

## Reporting

For each violation, surface:

```
| file:line | excerpt | why blocked | suggested action |
```

`suggested action` is one of:
- `delete` (default — most common)
- `rewrite as one-line non-obvious-logic note` (when the comment carries real information)
- `move to docs/` (when the comment is long-form prose)
- `move to commit message` (when it's historical)

## Authorization

Like every commit-guard rule, the user can override per-commit with:

```
allow comment at <file:line> because <reason>
```

But the default decision on any comment is **delete**.
