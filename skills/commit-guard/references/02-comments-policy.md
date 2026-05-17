# Comments Policy — Strict

Code is self-documenting. Comments are exceptions, not defaults.

## Banned

- **Narrative comments** explaining what the code does line-by-line. The code already says that.
- **Docblocks summarizing a class/function/file** when the name already describes it.
- **Historical commentary** ("we used to do X but switched to Y because Z"). Use `git log` and commit messages.
- **Deprecated/temporary verbose paragraphs**. One short `// TODO(@handle):` line max.
- **Obvious-code comments**: `// loop over items`, `// returns the user`, `// initialize state`, `// create a new instance`, `// import dependencies`.
- **Section header comments**: `// ---- Helpers ----`, `/* ===== Auth ===== */`, `// region Foo / endregion`.
- **Commented-out code**. Delete it. Git remembers.
- **Banner comments** with ASCII art or decorative borders.
- **AI-generated explanation drift**: long-form essays about why a one-liner exists.

## Allowed

1. **Static analysis annotations** when required by the tool:
   - PHP: `@var`, `@property`, `@method`, `@param`/`@return` only when needed for generics or mixed types.
   - TypeScript: TSDoc only for exported generics that can't be inferred.
   - Go: GoDoc on every exported symbol. Must start with the symbol name. One sentence minimum.
   - Python: type hints + brief docstring on public functions (PEP 257) — one-line preferred.
   - Rust: `///` doc comments on `pub` items.
2. **One-line `// TODO(@handle):` / `// FIXME(@handle):`** flags. Handle is required so blame is clear.
3. **≤1-line non-obvious-logic note** when an experienced reader would misread the code without it. Example:
   ```go
   // bitcast: reinterpret the uint64 as IEEE 754 without conversion.
   bits := math.Float64bits(f)
   ```
   The note explains a non-obvious mechanism, in one line, with the reason.
4. **License headers** when required by the project (SPDX format preferred).
5. **`@ts-expect-error` / `// eslint-disable-next-line <rule>` / `//go:build ...`** — tool directives, not comments per se.

## Detection patterns to flag

The skill should flag any of these patterns in the staged diff:

- Multi-line `/* */` blocks that aren't license headers or TSDoc.
- `//` or `#` comments longer than one line where the next non-comment line is obvious code.
- Comments that repeat the function name or class name as English prose.
- Comments containing AI-tell phrases ("This function is responsible for...", "Here we...", "The purpose of this code...").
- Section dividers (regex: `^//\s*[-=*]{3,}` or `^//\s*region\b`).
- Commented-out code (heuristic: comment lines that parse as valid code in the file's language).

## Reporting

For each violation, surface:

```
| file:line | excerpt | why blocked | suggested action |
```

Where `suggested action` is one of: `delete`, `convert to GoDoc/TSDoc/PHPDoc`, `rewrite as one-line note`, `move to commit message`.
