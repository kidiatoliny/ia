# Python

## Manifest
- `pyproject.toml`
- `version` field present under `[project]` or `[tool.poetry]`

## Test command
- Prefer `pytest`
- Detect runner: `pytest` in dev deps, or `[tool.poetry]` → `poetry run pytest`, or `uv` if `uv.lock` present

## Setup steps (workflow)
```yaml
      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -e ".[dev]"
```

Variations:
- Poetry: `pipx install poetry && poetry install`
- uv: `pip install uv && uv sync`

Python version: read from `pyproject.toml` `requires-python` / default 3.12.

## Version bump
Ask user. If on, use `tomlq` or python inline:

```yaml
      - name: Bump pyproject version
        run: |
          VERSION=${GITHUB_REF_NAME#v}
          python -c "import tomllib, pathlib; \
                     data = pathlib.Path('pyproject.toml').read_text(); \
                     import re; \
                     out = re.sub(r'(?m)^version = \".*\"', f'version = \"${VERSION}\"', data, count=1); \
                     pathlib.Path('pyproject.toml').write_text(out)"
```

## MANIFEST_FILES in commit
`pyproject.toml` (and lockfile if regen needed).
