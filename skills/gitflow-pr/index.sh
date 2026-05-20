#!/usr/bin/env bash
set -euo pipefail

# gitflow-pr: create PR after commit + push
# Hooks (gitflow-guard, commit-guard) handle commit/push validation
# This skill infers base branch and creates PR
# Usage: /gitflow-pr [--base branch]

usage() {
  cat >&2 <<'EOF'
Usage: /gitflow-pr [--base <branch>]

Creates PR with gitflow defaults.
Base branch inferred from feature branch name or --base override.

Examples:
  /gitflow-pr
  /gitflow-pr --base main
EOF
  exit 1
}

base_branch=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      base_branch="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      shift
      ;;
  esac
done

# Verify git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "error: not in a git repository" >&2
  exit 1
fi

cwd=$(git rev-parse --show-toplevel)
current_branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD)

# Infer base if not provided
if [[ -z "$base_branch" ]]; then
  if git -C "$cwd" branch -a | grep -qE "remotes/origin/milestone/v"; then
    base_branch=$(git -C "$cwd" branch -a | grep -E "remotes/origin/milestone/v" | head -1 | sed 's|remotes/origin/||')
  else
    base_branch="main"
  fi
fi

echo "Current branch: $current_branch"
echo "PR base: $base_branch"
echo

# Create PR (commit-guard marker)
mkdir -p "${TMPDIR:-/tmp}/commit-guard"
touch "${TMPDIR:-/tmp}/commit-guard/ok"

gh -C "$cwd" pr create --base "$base_branch" || {
  echo "error: PR creation failed" >&2
  exit 1
}

echo "✓ PR created"
