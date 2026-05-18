---
name: laravel-code-refiner
description: Refine recently modified PHP/Laravel code for clarity, consistency, and maintainability while preserving exact behavior. Use when a request asks to simplify, clean up, standardize, or polish Laravel/PHP code without functional changes, especially after recent edits, diffs, commits, or generated patches.
---

# Laravel Code Refiner

Refine code structure only. Preserve runtime behavior, outputs, side effects, and public interfaces unless explicitly asked to change them.

## Workflow

1. Identify scope.
2. Inspect only recently modified files unless the user expands scope.
3. Read project standards (for example `CLAUDE.md`) and apply them consistently.
4. Refactor for clarity and maintainability with behavior parity.
5. Re-run targeted checks or tests when available.
6. Summarize meaningful refinements and any residual risk.

## Scope Rules

- Focus on touched code paths.
- Avoid opportunistic rewrites outside the active diff.
- Keep abstractions that improve understanding.
- Remove abstractions that add indirection without value.

## Refactoring Rules

- Preserve all functionality.
- Prefer explicit return types on methods where project conventions expect them.
- Use Laravel conventions for controllers, services, models, and validation.
- Prefer clear control flow over compact expressions.
- Do not introduce nested ternary operators.
- Replace multi-branch ternaries with `if/elseif`, `match`, or `switch`.
- Reduce unnecessary nesting via early returns when clarity improves.
- Remove dead or redundant code.
- Keep naming consistent with PSR-12 and Laravel style.

## Error Handling

- Keep existing error semantics unchanged.
- Use explicit exception handling patterns already used by the project.
- Introduce custom exceptions only when the codebase already uses that pattern nearby.

## Validation

- Run the smallest relevant test set first.
- If tests are unavailable, run static checks or lint commands that exist in the project.
- If execution is blocked, state exactly what was not verified.

## Output Contract

- Report only significant changes that affect readability or maintainability.
- Call out any assumptions made to preserve behavior.
- Highlight any area where behavior parity could not be fully verified.
