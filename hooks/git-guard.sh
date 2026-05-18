#!/usr/bin/env bash
set -euo pipefail

MARKER_DIR="${TMPDIR:-/tmp}/commit-guard"
MARKER="$MARKER_DIR/ok"
PENDING="$MARKER_DIR/pending"
TTL=300

mkdir -p "$MARKER_DIR"

input=$(cat)
command=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null || true)

if [ -f "$PENDING" ]; then
  if printf '%s' "$command" | grep -qE "(touch|tee|cp|mv|ln)[[:space:]]+[^|;&]*${MARKER}\b"; then
    cat >&2 <<EOF
BLOCKED by commit-guard hook: $command

Pending commit-guard authorization exists ($PENDING). The assistant
cannot create the ok marker by itself. Wait for the user to reply with
the exact authorization phrase printed by the skill.
EOF
    exit 2
  fi
  if printf '%s' "$command" | grep -qE "(>|>>)[[:space:]]*${MARKER}\b"; then
    cat >&2 <<EOF
BLOCKED by commit-guard hook: $command

Pending commit-guard authorization exists ($PENDING). The assistant
cannot create the ok marker by itself via redirection. Wait for the
user to reply with the exact authorization phrase.
EOF
    exit 2
  fi
fi

if ! printf '%s' "$command" | grep -qE '(^|[^a-zA-Z])(git[[:space:]]+commit|git[[:space:]]+push|gh[[:space:]]+pr[[:space:]]+create|gh[[:space:]]+release[[:space:]]+create)([^a-zA-Z]|$)'; then
  exit 0
fi

cwd=$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null || true)
case "$cwd" in
  "$HOME/.claude"|"$HOME/.claude/"*)
    exit 0
    ;;
esac
case "$command" in
  *"cd $HOME/.claude"*|*"cd ~/.claude"*)
    exit 0
    ;;
esac

is_push=false
if printf '%s' "$command" | grep -qE '(^|[^a-zA-Z])(git[[:space:]]+push|gh[[:space:]]+pr[[:space:]]+create|gh[[:space:]]+release[[:space:]]+create)([^a-zA-Z]|$)'; then
  is_push=true
fi

is_commit=false
if printf '%s' "$command" | grep -qE '(^|[^a-zA-Z])git[[:space:]]+commit([^a-zA-Z]|$)'; then
  is_commit=true
fi

if [ "$is_commit" = "true" ]; then
  subject=""
  msg=$(CMD="$command" python3 -c '
import os, re, sys
cmd = os.environ.get("CMD", "")
m = re.search(r"-m\s+\x27((?:[^\x27]|\x27\\\x27\x27)*)\x27", cmd) or re.search(r"-m\s+\"((?:\\.|[^\"\\])*)\"", cmd)
if not m:
    sys.exit(1)
raw = m.group(1)
raw = raw.replace("\x27\\\x27\x27", "\x27").replace("\\\"", "\"").replace("\\\\", "\\").replace("\\$", "$")
m2 = re.search(r"\$\(cat\s*<<\s*\x27?(\w+)\x27?\s*\n(.*?)\n\1\s*\)", raw, re.S)
if m2:
    raw = m2.group(2)
first_line = raw.lstrip().split("\n", 1)[0]
print(first_line)
' 2>/dev/null || true)
  if [ -n "$msg" ]; then
    subject=$(printf '%s' "$msg" | head -n1)
  fi

  if [ -n "$subject" ]; then
    if ! printf '%s' "$subject" | grep -qE '^(feat|fix|chore|docs|style|refactor|perf|test|build|ci|revert)(\([a-z0-9._-]+\))?!?: .+'; then
      cat >&2 <<EOF
BLOCKED by commit-guard hook: commit message does not follow Conventional Commits.

Subject: "$subject"

Required form:
  type(scope): description
  type!: description           (breaking change)
  type(scope)!: description    (breaking change with scope)

Allowed types:
  feat, fix, chore, docs, style, refactor, perf, test, build, ci, revert

Examples:
  feat(auth): add OAuth login flow
  fix(payment): handle declined card error
  chore(deps): bump phpunit to ^11.0
  refactor(api)!: drop legacy v1 endpoints

Rewrite the message and re-run.
EOF
      exit 2
    fi
  fi
fi

marker_fresh=false
if [ -f "$MARKER" ]; then
  if mtime=$(stat -f %m "$MARKER" 2>/dev/null); then :
  else mtime=$(stat -c %Y "$MARKER" 2>/dev/null || echo 0); fi
  age=$(( $(date +%s) - mtime ))
  if [ "$age" -lt "$TTL" ]; then
    marker_fresh=true
  fi
  rm -f "$MARKER"
fi

if [ "$marker_fresh" = "false" ]; then
  cat >&2 <<EOF
BLOCKED by commit-guard hook: $command

Mandatory rule: commit-guard validation must run and pass before any
git commit, git push, gh pr create, or gh release create.

Required next steps for the agent:

  1. Invoke the commit-guard skill (Skill tool, name="commit-guard")
     or call /commit-guard.
  2. Run all checks; fix violations or authorize per change.
  3. Touch the marker:
        touch "$MARKER"
  4. Re-issue the git/gh command.
EOF
  exit 2
fi

if [ "$is_push" = "true" ]; then
  target_dir="$cwd"
  cd_target=$(printf '%s' "$command" | sed -nE 's/.*[[:space:]]cd[[:space:]]+("?)([^"&|;]+)\1.*/\2/p' | head -n1 | sed 's/[[:space:]]*$//')
  if [ -n "$cd_target" ] && [ -d "$cd_target" ]; then
    target_dir="$cd_target"
  fi
fi

if [ "$is_push" = "true" ] && [ -n "$target_dir" ] && [ -f "$target_dir/composer.json" ]; then
  cwd="$target_dir"
  has_test_script=$(jq -r '.scripts.test // empty' "$cwd/composer.json" 2>/dev/null || true)
  if [ -n "$has_test_script" ]; then
    is_laravel=false
    if [ -f "$cwd/artisan" ] && jq -e '.require["laravel/framework"]' "$cwd/composer.json" >/dev/null 2>&1; then
      is_laravel=true
    fi
    if jq -e '.require["nunomaduro/essentials"], .["require-dev"]["nunomaduro/essentials"]' "$cwd/composer.json" >/dev/null 2>&1; then
      is_laravel=true
    fi

    if [ "$is_laravel" = "true" ]; then
      echo ">> commit-guard hard-enforce: running composer test before allowing $command" >&2
      cd "$cwd"
      if ! composer test 1>&2; then
        cat >&2 <<EOF

BLOCKED by commit-guard hard-enforce: composer test failed.

This is the Laravel pre-push composite gate. Every script under
composer.json scripts.test must pass before a push is allowed. No
filtered-subset substitute, no "pre-existing" claim without the
4-step protocol in commit-guard's php.md adapter.
EOF
        exit 2
      fi
    fi
  fi
fi

exit 0
