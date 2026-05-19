#!/usr/bin/env bash
# Programmatic comment-policy scan for commit-guard.
#
# Scans the staged diff for any leading-line `//`, `/* */`, or `#` comments
# in source files. Allowed exceptions:
#
#   - TODO(@handle) / FIXME(@handle) single-line flags
#   - Tool pragmas: //go:build, // +build, // eslint-disable*, // ts-expect-error,
#     // @ts-*, # noqa, # type: ignore, # pylint:, # mypy:, // biome-ignore
#   - SPDX license headers: // SPDX-License-Identifier: ..., # SPDX-...
#   - Shebangs: first-line `#!`
#
# Output (stdout):
#   <file>:<line>:<excerpt>
#
# Exit code:
#   0 — no violations
#   1 — violations found (printed to stdout)

set -uo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
cd "$repo_root" || exit 0

files=$(git diff --cached --name-only --diff-filter=AM 2>/dev/null \
  | grep -E '\.(go|ts|tsx|js|jsx|mjs|cjs|php|rs|py|rb|swift|kt|java|cs|scala)$' || true)

if [ -z "$files" ]; then
  exit 0
fi

violations=0

is_allowed_pragma() {
  local line="$1"
  case "$line" in
    *"TODO("*"@"*")"*) return 0 ;;
    *"FIXME("*"@"*")"*) return 0 ;;
    *"//go:build"*) return 0 ;;
    *"// +build"*) return 0 ;;
    *"// eslint-disable"*) return 0 ;;
    *"// eslint-enable"*) return 0 ;;
    *"// biome-ignore"*) return 0 ;;
    *"// @ts-"*) return 0 ;;
    *"// ts-expect-error"*) return 0 ;;
    *"# noqa"*) return 0 ;;
    *"# type: ignore"*) return 0 ;;
    *"# pylint:"*) return 0 ;;
    *"# mypy:"*) return 0 ;;
    *"# pragma"*) return 0 ;;
    *"SPDX-License-Identifier:"*) return 0 ;;
    "#!"*) return 0 ;;
  esac
  return 1
}

while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ -f "$f" ] || continue

  ln=0
  while IFS= read -r line; do
    ln=$((ln + 1))
    trimmed="${line#"${line%%[![:space:]]*}"}"
    case "$trimmed" in
      "//"*|"#"*|"/*"*)
        if is_allowed_pragma "$trimmed"; then
          continue
        fi
        echo "$f:$ln: $trimmed"
        violations=$((violations + 1))
        ;;
    esac
  done < "$f"
done <<EOF
$files
EOF

if [ "$violations" -gt 0 ]; then
  exit 1
fi
exit 0
