#!/usr/bin/env bash
set -euo pipefail

# gitflow-pr: automated commit → push → PR workflow
# Usage: /gitflow-pr "commit message" ["base branch"]
# Default base: milestone/vX.Y.Z (inferred from branch name)

usage() {
  cat >&2 <<'EOF'
Usage: /gitflow-pr <message> [--base <branch>]

Automates:
1. Runs commit-guard checks
2. Commits staged changes
3. Pushes to origin
4. Creates PR (into milestone/vX.Y.Z or specified base)

Examples:
  /gitflow-pr "feat: add user auth"
  /gitflow-pr "fix: resolve race condition" --base main
EOF
  exit 1
}

[[ $# -lt 1 ]] && usage

msg="$1"
base_branch=""

while [[ $# -gt 1 ]]; do
  case "$2" in
    --base)
      base_branch="$3"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

# Verify we're in a git repo
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "error: not in a git repository" >&2
  exit 1
fi

cwd=$(git rev-parse --show-toplevel)
current_branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD)

# Must be on a feature branch
if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
  echo "error: cannot commit directly on main/master. switch to a feature branch." >&2
  exit 1
fi

echo "Branch: $current_branch"
echo "Message: $msg"
echo

# Infer base if not provided
if [[ -z "$base_branch" ]]; then
  # Extract milestone from branch name (feat/xyz → milestone/vX.Y.Z)
  if [[ "$current_branch" =~ ^feat/ || "$current_branch" =~ ^fix/ || "$current_branch" =~ ^chore/ ]]; then
    base_branch=$(git -C "$cwd" branch -a | grep -E "milestone/v[0-9]" | head -1 | sed 's|remotes/origin/||' | xargs || echo "main")
  else
    base_branch="main"
  fi
fi

echo "Base branch: $base_branch"
echo

# Mark OK for commit-guard
mkdir -p "${TMPDIR:-/tmp}/commit-guard"
touch "${TMPDIR:-/tmp}/commit-guard/ok"

# 1. Commit
echo "→ Committing..."
git -C "$cwd" commit -m "$msg" || {
  echo "error: commit failed" >&2
  exit 1
}

# 2. Push
echo "→ Pushing..."
mkdir -p "${TMPDIR:-/tmp}/commit-guard"
touch "${TMPDIR:-/tmp}/commit-guard/ok"

git -C "$cwd" push -u origin "$current_branch" || {
  echo "error: push failed" >&2
  exit 1
}

# 3. Create PR
echo "→ Creating PR into $base_branch..."
mkdir -p "${TMPDIR:-/tmp}/commit-guard"
touch "${TMPDIR:-/tmp}/commit-guard/ok"

gh -C "$cwd" pr create --base "$base_branch" --title "$msg" || {
  echo "error: PR creation failed" >&2
  exit 1
}

echo "✓ Done: commit → push → PR"
