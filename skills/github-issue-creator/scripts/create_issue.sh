#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <owner/repo> <title> <body-file> <comma-separated-labels>" >&2
  exit 1
fi

repo="$1"
title="$2"
body_file="$3"
labels_csv="$4"

if [[ ! -f "$body_file" ]]; then
  echo "Body file not found: $body_file" >&2
  exit 1
fi

IFS=',' read -r -a labels <<< "$labels_csv"
json_labels="$(printf '%s\n' "${labels[@]}" | jq -R . | jq -s .)"

issue_url="$(gh api "repos/${repo}/issues" \
  --method POST \
  --raw-field title="$title" \
  --raw-field body="$(cat "$body_file")" \
  --field labels="$json_labels" \
  --jq '.html_url')"

printf '%s\n' "$issue_url"
