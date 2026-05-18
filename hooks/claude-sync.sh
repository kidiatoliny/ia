#!/usr/bin/env bash
set -euo pipefail

REPO="$HOME/.claude"
LOG="$REPO/.last-sync.log"

cd "$REPO" || exit 0

if [ ! -d .git ]; then
  exit 0
fi

if git diff --quiet && git diff --cached --quiet && [ -z "$(git status --porcelain)" ]; then
  exit 0
fi

ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)

git add -A >/dev/null 2>&1 || true

files_changed=$(git diff --cached --name-only | head -5 | paste -sd ',' -)
count=$(git diff --cached --name-only | wc -l | tr -d ' ')

subject="chore(auto-sync): $count file(s) [$ts]"
body="Auto-synced by Stop hook.

Files:
$(git diff --cached --name-only | sed 's/^/  - /')"

{
  echo "=== $ts ==="
  echo "subject: $subject"
} >> "$LOG" 2>&1

if git commit -m "$subject" -m "$body" >> "$LOG" 2>&1; then
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)
  if git push origin "$branch" >> "$LOG" 2>&1; then
    echo "pushed" >> "$LOG"
  else
    echo "push failed (committed locally)" >> "$LOG"
  fi
else
  echo "commit failed" >> "$LOG"
fi

exit 0
