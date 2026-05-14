---
name: akira-release-setup
description: Provisions the canonical Akira release pipeline in any desktop app repo (Tauri or Wails). Generates .github/workflows/build-and-release.yml + .github/scripts/publish-release.sh so every push of a vX.Y.Z[-suffix] tag builds, signs, and uploads artifacts to DigitalOcean Spaces under the unified {channel}/v{VERSION}/ layout that Akira Billing reads. Use when the user says "setup release", "add release workflow", "ship to bucket", "configure CI release", "install release pipeline", or asks how to publish a new Akira desktop app.
---

# Akira release setup

Installs the standardized release pipeline inside an Akira desktop app
repository. Same layout for every app, regardless of bundler.

## Bucket layout this pipeline produces

```
{S3_BUCKET}/
  stable/
    latest.json
    v{X.Y.Z}/{app_key}_{X.Y.Z}_{arch}.app.{tar.gz|zip}[.sig]
    v{X.Y.Z}/{app_key}_{X.Y.Z}_{arch}.dmg
  beta/
    latest.json
    v{X.Y.Z-beta.N}/...
  nightly/
    latest.json
    v{X.Y.Z-nightly.N}/...
  releases/
    latest.json   ← legacy stable shim, points at /stable/v.../...
```

`releases/latest.json` shim only on stable runs; can be turned off later
with `DISABLE_LEGACY_SHIM=1` once every shipped app polls the Akira
Billing endpoint.

## How channel is decided

The publish script reads the git tag that triggered the workflow and
picks the channel:

| Tag pattern                | Channel  |
| -------------------------- | -------- |
| `vX.Y.Z`                   | stable   |
| `vX.Y.Z-alpha.N`           | beta     |
| `vX.Y.Z-beta.N`            | beta     |
| `vX.Y.Z-rc.N`              | beta     |
| `vX.Y.Z-nightly.N`         | nightly  |
| `nightly-YYYYMMDD`         | nightly  |

The CI does not need any environment switch — the tag is the channel.
Override by setting `CHANNEL=...` in the publish step if needed.

For scheduled nightly builds, add a cron-triggered job that computes a
synthetic `v0.X.0-nightly.YYYYMMDDHHMM` tag and pushes it before the
release workflow fires.

## Setup procedure

When invoked, execute these steps in order. Use the user's current
working directory as the target app repo.

### 1. Detect bundler

- Tauri  → `src-tauri/tauri.conf.json` exists at repo root.
- Wails  → `wails.json` exists OR `main.go` + `frontend/` directory.
- Neither → ask the user which bundler the app uses; if neither, abort.

### 2. Resolve parameters

Collect the following. Infer defaults from the repo, then ASK the user
to confirm before writing files.

| Variable        | Default / Inference                                                                  |
| --------------- | ------------------------------------------------------------------------------------ |
| `APP_KEY`       | Slug of the package.json `name` (lowercase, hyphens). Must match `products.key` in Akira Billing. |
| `PRODUCT_NAME`  | (Wails only) The `productName` in `wails.json` OR display name. Used for `{PRODUCT_NAME}.app`. |
| `BUNDLE_ID`     | (Wails only) Reverse-DNS bundle id (`foundation.akira.<app>` if unsure).             |
| `S3_BUCKET`     | DigitalOcean Spaces bucket. Default to `APP_KEY` if unsure.                          |
| `S3_ENDPOINT`   | `https://nyc3.digitaloceanspaces.com` unless told otherwise.                         |
| `CDN_BASE`      | `https://{S3_BUCKET}.nyc3.cdn.digitaloceanspaces.com` (no trailing `/releases`).     |

### 3. Copy + render the workflow

Source files inside this skill:

- `templates/tauri-build-and-release.yml`
- `templates/wails-build-and-release.yml`
- `templates/publish-release.sh`

For the chosen bundler:

1. Read the matching template file.
2. Replace the `env:` block values with the user-confirmed parameters.
3. Write the rendered YAML to `.github/workflows/build-and-release.yml`
   in the target repo.
4. Copy `templates/publish-release.sh` verbatim to
   `.github/scripts/publish-release.sh` in the target repo and make
   sure it is executable (`chmod +x`).

If either destination already exists, show a diff and ask before
overwriting.

### 4. Verify required repo files

- **Tauri:** `src-tauri/tauri.conf.json` should declare an `updater`
  block with the Akira Billing endpoint:
  ```jsonc
  "plugins": {
    "updater": {
      "endpoints": [
        "https://billing.akira.foundation/api/v1/downloads/<APP_KEY>/<CHANNEL>/latest"
      ],
      "pubkey": "..."
    }
  }
  ```
  Warn (do not edit) if the current config still hardcodes the raw CDN
  URL.
- **Wails:** `internal/updater/config.go` (or equivalent) should declare
  `ManifestURL` pointing at the same Akira Billing endpoint and have a
  real public key (no `REPLACE_WITH_MINISIGN_PUBLIC_KEY` placeholder).
  The workflow has a guard that fails the build if the placeholder is
  still present.

### 5. Required GitHub secrets

Tell the user to set these in repo Settings → Secrets and variables →
Actions before pushing a tag:

Always:
- `DO_SPACES_KEY`
- `DO_SPACES_SECRET`
- `APPLE_CERTIFICATE`
- `APPLE_CERTIFICATE_PASSWORD`
- `APPLE_SIGNING_IDENTITY`
- `APPLE_ID`
- `APPLE_PASSWORD`
- `APPLE_TEAM_ID`

Tauri only:
- `TAURI_SIGNING_PRIVATE_KEY`
- `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`

Wails only:
- `MINISIGN_PRIVATE_KEY`
- `MINISIGN_PRIVATE_KEY_PASSWORD`

### 6. Tell the user how to release

After files are written, print this checklist exactly:

```
Files written:
  .github/workflows/build-and-release.yml
  .github/scripts/publish-release.sh

Next:
  1. Confirm the secrets above are set in the GitHub repo.
  2. Make sure {S3_BUCKET} exists on DigitalOcean Spaces and is
     publicly readable.
  3. Tag and push:
       git tag v0.1.0           # → stable
       git tag v0.1.0-beta.1    # → beta
       git tag v0.1.0-nightly.1 # → nightly
       git push origin --tags
  4. The workflow runs, builds for darwin/aarch64 + darwin/x86_64,
     signs + notarizes, uploads to {S3_BUCKET}/{channel}/v{version}/,
     and writes {channel}/latest.json. On stable, it also mirrors to
     releases/latest.json for already-deployed clients.
```

## Notes

- The publish script auto-derives channel from the tag; nothing else
  in CI needs to know about channels.
- The same `publish-release.sh` is used by Tauri and Wails apps; only
  the `BUNDLE` extensions differ (`.app.tar.gz` vs `.app.zip`).
- Do not commit the templates into the target app's source tree —
  only the rendered workflow and the script. The skill itself is the
  source of truth.
