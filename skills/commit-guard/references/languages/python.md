# Python adapter

## Detection

- `pyproject.toml`, `setup.py`, `Pipfile`, or `requirements.txt` present.
- Staged `*.py` files.

## Required commands

Use what the project defines in `pyproject.toml` / `tox.ini` / `Makefile`. Fallback defaults:

| Stage      | Command                              |
|------------|--------------------------------------|
| Format     | `ruff format --check .`              |
| Lint       | `ruff check .`                       |
| Typecheck  | `mypy .` (only if mypy config exists) |
| Test       | `pytest`                             |
| Dead code  | `ruff check --select F401,F841 .` or `vulture` if installed |

## Naming

PEP 8 + PEP 257.

- Modules: `snake_case.py`.
- Packages: `snake_case`.
- Classes: `PascalCase`.
- Functions/methods/variables: `snake_case`.
- Constants: `UPPER_SNAKE_CASE`.
- Private (intra-module): `_leading_underscore`.
- Magic methods: `__dunder__`.
- Type variables: `T`, `U` (single capital) or `KeyT`, `ValueT` (suffix `T`).

## Public API surface

- Symbols exported via `__all__` in a module's `__init__.py`.
- Symbols not prefixed with `_`.
- Routes (FastAPI, Django, Flask).
- CLI commands and their flags.
- Pydantic models used as request/response schemas.

## Test detection

For modified `pkg/foo.py`, expect change in `tests/test_foo.py` or `pkg/tests/test_foo.py`. Pytest auto-discovers `test_*.py` and `*_test.py`.

## Common bad patterns

- `print()` in source unless explicit CLI output.
- Bare `except:` (catches `SystemExit`/`KeyboardInterrupt`).
- Mutable default arguments (`def f(x=[])`).
- `from foo import *`.
- `eval()`, `exec()`.
- `os.system()` (use `subprocess`).
- Long functions: split before they pass the 300-line file cap, but also individual functions > 50 lines should be split.
- Missing type hints on public functions (when project uses type hints).
- `Optional[X]` instead of `X | None` on Python 3.10+ (project-style dependent).
- Missing docstrings on public functions and classes (PEP 257 — short one-liner is enough).
- Excess `# noqa` without rule code.
- Circular imports (surface during build/typecheck).

## File length

300-line cap. Convert long modules to packages (directory with `__init__.py`) split by responsibility.
