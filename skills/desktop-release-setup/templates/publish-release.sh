#!/usr/bin/env bash
#
# Canonical Akira release publisher.
#
# Layout on S3 (one bucket per Akira app):
#
#   {channel}/latest.json
#   {channel}/v{VERSION}/{app_key}_{VERSION}_{arch}.app.tar.gz[.sig|.dmg]
#
# Channels: stable | beta | nightly. Top-level siblings, no special case.
#
# Backward-compat shim for already-deployed Tauri/Wails clients that hardcode
# `https://{cdn}/releases/latest.json`: when CHANNEL=stable we ALSO mirror
# the manifest to `releases/latest.json`. URLs inside both copies point at
# the canonical `stable/v{VERSION}/...` artifact paths. Once every shipped
# app polls the Akira Billing endpoint instead of the CDN directly, the
# shim can be dropped (DISABLE_LEGACY_SHIM=1).
#
# Channel detection from tag:
#   vX.Y.Z              -> stable
#   vX.Y.Z-beta.N       -> beta
#   vX.Y.Z-rc.N         -> beta
#   vX.Y.Z-alpha.N      -> beta
#   vX.Y.Z-nightly.N    -> nightly
#   nightly-YYYYMMDD    -> nightly
#
# Required env:
#   APP_KEY               unified-dev | spectra | orbit | debugger-app | ...
#   VERSION               0.9.0 or 0.10.0-beta.1 (no leading v)
#   S3_BUCKET             do spaces bucket name
#   S3_ENDPOINT           e.g. https://nyc3.digitaloceanspaces.com
#   CDN_BASE              CDN origin (no trailing /releases). The script
#                         normalizes either way.
#   AWS_ACCESS_KEY_ID
#   AWS_SECRET_ACCESS_KEY
#
# Optional artifact paths (any subset; missing files skipped):
#   AARCH64_BUNDLE        .app.tar.gz (Tauri) or .app.zip (Wails)
#   AARCH64_SIG           defaults to BUNDLE + ".sig"
#   AARCH64_DMG
#   X86_64_BUNDLE / X86_64_SIG / X86_64_DMG
#   LINUX_APPIMAGE / LINUX_APPIMAGE_SIG
#   WINDOWS_MSI / WINDOWS_NSIS
#
# Optional flags:
#   CHANNEL               override auto-detection
#   NOTES                 release notes (defaults to "Release ${VERSION}")
#   DISABLE_LEGACY_SHIM   set to 1 to skip the releases/latest.json mirror

set -euo pipefail

require() {
  for var in "$@"; do
    if [ -z "${!var:-}" ]; then
      echo "ERROR: $var is required" >&2
      exit 1
    fi
  done
}

require APP_KEY VERSION S3_BUCKET S3_ENDPOINT CDN_BASE \
  AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY

detect_channel() {
  if [ -n "${CHANNEL:-}" ]; then
    echo "$CHANNEL"
    return
  fi

  case "$VERSION" in
    *-nightly*) echo "nightly" ;;
    *-alpha*|*-beta*|*-rc*) echo "beta" ;;
    nightly-*) echo "nightly" ;;
    *) echo "stable" ;;
  esac
}

CHANNEL="$(detect_channel)"

# CDN_BASE may already include a /releases tail from legacy workflows.
# Strip it so the rest of the script can compose paths uniformly.
CDN_BASE="${CDN_BASE%/}"
CDN_BASE="${CDN_BASE%/releases}"

echo ">> channel=${CHANNEL} version=${VERSION} app=${APP_KEY}"

s3() {
  aws s3 "$@" --endpoint-url "$S3_ENDPOINT" --region us-east-1
}

upload_artifact() {
  local path="$1"
  [ -z "$path" ] && return 0
  [ ! -f "$path" ] && { echo "  ! skip missing: $path"; return 0; }

  local name; name="$(basename "$path")"
  local dest="s3://${S3_BUCKET}/${CHANNEL}/v${VERSION}/${name}"
  echo "  uploading ${name} -> ${dest}"
  s3 cp "$path" "$dest" --acl public-read
}

sig_path_for() {
  local bundle="$1" sig_override="$2"
  if [ -n "$sig_override" ]; then echo "$sig_override"
  elif [ -n "$bundle" ];      then echo "${bundle}.sig"
  else                              echo ""
  fi
}

AARCH64_BUNDLE="${AARCH64_BUNDLE:-}"
AARCH64_SIG="$(sig_path_for "$AARCH64_BUNDLE" "${AARCH64_SIG:-}")"
AARCH64_DMG="${AARCH64_DMG:-}"
X86_64_BUNDLE="${X86_64_BUNDLE:-}"
X86_64_SIG="$(sig_path_for "$X86_64_BUNDLE" "${X86_64_SIG:-}")"
X86_64_DMG="${X86_64_DMG:-}"
LINUX_APPIMAGE="${LINUX_APPIMAGE:-}"
LINUX_APPIMAGE_SIG="${LINUX_APPIMAGE_SIG:-}"
WINDOWS_MSI="${WINDOWS_MSI:-}"
WINDOWS_NSIS="${WINDOWS_NSIS:-}"

upload_artifact "$AARCH64_BUNDLE"
upload_artifact "$AARCH64_SIG"
upload_artifact "$AARCH64_DMG"
upload_artifact "$X86_64_BUNDLE"
upload_artifact "$X86_64_SIG"
upload_artifact "$X86_64_DMG"
upload_artifact "$LINUX_APPIMAGE"
upload_artifact "$LINUX_APPIMAGE_SIG"
upload_artifact "$WINDOWS_MSI"
upload_artifact "$WINDOWS_NSIS"

url_for() {
  local path="$1"
  [ -z "$path" ] && return 0
  [ ! -f "$path" ] && return 0
  local name; name="$(basename "$path")"
  echo "${CDN_BASE}/${CHANNEL}/v${VERSION}/${name}" | sed 's/ /%20/g'
}

read_sig() {
  local sig_path="$1"
  [ -z "$sig_path" ] && return 0
  [ ! -f "$sig_path" ] && return 0
  cat "$sig_path"
}

AARCH64_URL="$(url_for "$AARCH64_BUNDLE")"
AARCH64_SIG_CONTENT="$(read_sig "$AARCH64_SIG")"
X86_64_URL="$(url_for "$X86_64_BUNDLE")"
X86_64_SIG_CONTENT="$(read_sig "$X86_64_SIG")"
LINUX_URL="$(url_for "$LINUX_APPIMAGE")"
LINUX_SIG_CONTENT="$(read_sig "$LINUX_APPIMAGE_SIG")"
WINDOWS_URL="$(url_for "${WINDOWS_MSI:-$WINDOWS_NSIS}")"

PUB_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
NOTES="${NOTES:-Release ${VERSION}}"

JQ_ARGS=(
  --arg version "$VERSION"
  --arg channel "$CHANNEL"
  --arg pub_date "$PUB_DATE"
  --arg notes "$NOTES"
)

JQ_OBJ='{
  version: $version,
  channel: $channel,
  notes: $notes,
  pub_date: $pub_date,
  platforms: {}
}'

add_platform() {
  local key="$1" url="$2" sig="$3"
  [ -z "$url" ] && return 0
  JQ_ARGS+=(--arg "${key}_url" "$url" --arg "${key}_sig" "$sig")
  JQ_OBJ=$(printf '%s | .platforms["%s"] = {signature: $%s_sig, url: $%s_url}' \
    "$JQ_OBJ" "$key" "$key" "$key")
}

add_platform "darwin-aarch64" "$AARCH64_URL" "$AARCH64_SIG_CONTENT"
add_platform "darwin-x86_64"  "$X86_64_URL"  "$X86_64_SIG_CONTENT"
add_platform "linux-x86_64"   "$LINUX_URL"   "$LINUX_SIG_CONTENT"
add_platform "windows-x86_64" "$WINDOWS_URL" ""

MANIFEST=$(jq -n "${JQ_ARGS[@]}" "$JQ_OBJ")

echo ">> latest.json:"
echo "$MANIFEST"

echo "$MANIFEST" > latest.json

# Canonical manifest at {channel}/latest.json.
s3 cp latest.json "s3://${S3_BUCKET}/${CHANNEL}/latest.json" \
  --acl public-read \
  --content-type application/json \
  --cache-control "no-cache"

# Legacy mirror at releases/latest.json so binaries shipped before the
# Akira-Billing endpoint cutover keep auto-updating. Stable only.
if [ "$CHANNEL" = "stable" ] && [ -z "${DISABLE_LEGACY_SHIM:-}" ]; then
  s3 cp latest.json "s3://${S3_BUCKET}/releases/latest.json" \
    --acl public-read \
    --content-type application/json \
    --cache-control "no-cache"
  echo ">> wrote legacy releases/latest.json shim"
fi

echo ">> done"
