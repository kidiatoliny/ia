#!/usr/bin/env bash
# Post-push hook: auto-create PR on gitflow feature branches
set -euo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || true)

# Only trigger on successful push
if ! printf '%s' "$command" | grep -qE 'git[[:space:]]+push'; then
  exit 0
fi

cwd=$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null || true)
[ -z "$cwd" ] && exit 0
[ ! -d "$cwd" ] && exit 0

# Get current branch
current_branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
[ -z "$current_branch" ] && exit 0

# Skip if on main/master
if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
  exit 0
fi

# Infer base branch
base_branch="main"
if git -C "$cwd" branch -a 2>/dev/null | grep -qE "remotes/origin/milestone/v"; then
  base_branch=$(git -C "$cwd" branch -a 2>/dev/null | grep -E "remotes/origin/milestone/v" | head -1 | sed 's|remotes/origin/||')
fi

# Check if PR already exists
if gh -C "$cwd" pr list --head "$current_branch" --json number 2>/dev/null | grep -q "number"; then
  exit 0
fi

# Create PR automatically
echo "Creating PR: $current_branch → $base_branch" >&2
gh -C "$cwd" pr create --base "$base_branch" 2>/dev/null || true

exit 0
