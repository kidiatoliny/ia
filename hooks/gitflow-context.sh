#!/usr/bin/env bash
# Injects setup-gitflow context when the user prompt is about
# issues, milestones, or branch workflows.
set -euo pipefail

input=$(cat)
prompt=$(printf '%s' "$input" | jq -r '.prompt // .user_prompt // ""' 2>/dev/null || true)

[ -z "$prompt" ] && exit 0

PATTERN='(/start-issue|/finish-milestone|/setup-branch-policy|/setup-gitflow|start[[:space:]]issue|iniciar[[:space:]]issue|trabalhar[[:space:]]n[ao][[:space:]]issue|fechar[[:space:]]milestone|merge[[:space:]]milestone|finish[[:space:]]milestone|criar[[:space:]]branch|feature[[:space:]]branch|milestone[[:space:]]branch|branch[[:space:]]protect|setup[[:space:]]gitflow|configurar[[:space:]]git)'
if printf '%s' "$prompt" | grep -qiE "$PATTERN"; then
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"[setup-gitflow] Milestone-branch workflow active. Use the setup-gitflow skill: /start-issue <LINEAR-ID> creates milestone/* + feat/* branches and updates Linear. /finish-milestone <vX.Y.Z> verifies all issues done and opens the merge PR. /setup-branch-policy installs GitHub Actions enforcement. Never commit or push directly to main."}}\n'
fi

exit 0
