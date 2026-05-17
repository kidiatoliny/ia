#!/usr/bin/env bash
set -euo pipefail

MARKER_DIR="${TMPDIR:-/tmp}/commit-guard"
MARKER="$MARKER_DIR/ok"
TTL=300

mkdir -p "$MARKER_DIR"

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || true)

if ! printf '%s' "$command" | grep -qE '(^|[^a-zA-Z])(git[[:space:]]+commit|git[[:space:]]+push|gh[[:space:]]+pr[[:space:]]+create|gh[[:space:]]+release[[:space:]]+create)([^a-zA-Z]|$)'; then
  exit 0
fi

if [ -f "$MARKER" ]; then
  if mtime=$(stat -f %m "$MARKER" 2>/dev/null); then :
  else mtime=$(stat -c %Y "$MARKER" 2>/dev/null || echo 0); fi
  age=$(( $(date +%s) - mtime ))
  if [ "$age" -lt "$TTL" ]; then
    rm -f "$MARKER"
    exit 0
  fi
  rm -f "$MARKER"
fi

cat >&2 <<EOF
BLOCKED by commit-guard hook: $command

Mandatory rule: commit-guard validation must run and pass before any
git commit, git push, gh pr create, or gh release create.

Required next steps for the agent:

  1. Invoke the commit-guard skill (Skill tool, name="commit-guard")
     or call /commit-guard. The skill reads
     ~/.claude/skills/commit-guard/SKILL.md and references/.

  2. Run all checks: 300-line file cap, conventional commit scopes,
     language-idiomatic naming, comments policy, AI-tells ban,
     secrets scan, dead-code removal, tests on every functional
     change, breaking-change discipline.

  3. Fix every reported violation, OR ask the user to explicitly
     authorize a per-change exception ("skip commit-guard", "allow
     emoji here", "no test for this change because <reason>").

  4. After commit-guard reports "clean" (or the user authorizes the
     exception), touch the marker file to unlock the next git command:
        touch "$MARKER"

  5. Re-issue the same git/gh command. The hook consumes the marker
     and allows the call to proceed.

This hook protects the user's quality bar. Do not try to bypass it
by chaining commands, eval, base64, or any other technique. Always
go through commit-guard.
EOF

exit 2
