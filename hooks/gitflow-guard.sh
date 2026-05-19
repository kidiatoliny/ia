#!/usr/bin/env bash
# Blocks direct commits/pushes to main or master.
# Part of the setup-gitflow milestone-branch workflow.
set -euo pipefail

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || true)

[ -z "$command" ] && exit 0

# Only care about git push or git commit
if ! printf '%s' "$command" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+(push|commit)([[:space:]]|$)'; then
  exit 0
fi

# Block: git push ... origin main / git push ... origin master
# Catches: git push origin main, git push -u origin main, git push origin HEAD:main, etc.
if printf '%s' "$command" | grep -qE 'git[[:space:]]+push\b' && \
   printf '%s' "$command" | grep -qE '[[:space:]](main|master)([[:space:]]|$|:)'; then
  cat >&2 <<'EOF'
BLOCKED by setup-gitflow: direct push to main/master is not allowed.

Use the milestone-branch workflow:
  1. Work on:   feat/<id>-slug   (branched from milestone/vX.Y.Z)
  2. PR into:   milestone/vX.Y.Z (never main)
  3. Release:   milestone/vX.Y.Z → main  (via PR, only when milestone complete)

Run /start-issue <LINEAR-ID> to set up branches automatically.
EOF
  exit 2
fi

# Block: git commit while HEAD is on main or master
if printf '%s' "$command" | grep -qE '(^|[;&|[:space:]])git[[:space:]]+commit\b'; then
  cwd=$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null || true)
  if [ -n "$cwd" ] && [ -d "$cwd" ]; then
    current_branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
    if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
      cat >&2 <<'EOF'
BLOCKED by setup-gitflow: committing directly on main/master is not allowed.

You are on the default branch. Switch to a feature branch first:
  git checkout milestone/vX.Y.Z
  git checkout -b feat/<id>-slug

Or run /start-issue <LINEAR-ID> to set up branches automatically.
EOF
      exit 2
    fi
  fi
fi

exit 0
