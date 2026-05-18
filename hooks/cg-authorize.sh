#!/usr/bin/env bash
set -euo pipefail

MARKER_DIR="${TMPDIR:-/tmp}/commit-guard"
PENDING="$MARKER_DIR/pending"
OK="$MARKER_DIR/ok"

mkdir -p "$MARKER_DIR"

input=$(cat)
prompt=$(printf '%s' "$input" | jq -r '.prompt // .user_prompt // ""' 2>/dev/null || true)

if [ -z "$prompt" ]; then
  exit 0
fi

token=$(printf '%s' "$prompt" | grep -oE '(^|[^[:alnum:]])cg:[[:space:]]*[A-Za-z0-9_-]+' | head -n1 | sed -E 's/.*cg:[[:space:]]*//')

if [ -z "$token" ]; then
  exit 0
fi

if [ "$token" = "cancel" ]; then
  rm -f "$PENDING" "$OK"
  printf 'commit-guard: pending authorization cancelled.\n' >&2
  exit 0
fi

if [ ! -f "$PENDING" ]; then
  printf 'commit-guard: no pending authorization. Token ignored.\n' >&2
  exit 0
fi

expected=$(cat "$PENDING" 2>/dev/null | head -n1 | tr -d '[:space:]')

if [ "$token" != "$expected" ]; then
  printf 'commit-guard: token mismatch. Expected %s, got %s.\n' "$expected" "$token" >&2
  exit 0
fi

ts=$(date +%s)
printf 'user-auth:%s:%s\n' "$token" "$ts" > "$OK"
rm -f "$PENDING"
printf 'commit-guard: authorized by user (token %s). Single-use marker armed.\n' "$token" >&2
exit 0
