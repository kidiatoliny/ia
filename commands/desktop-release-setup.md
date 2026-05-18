---
name: desktop-release-setup
description: Provisions the canonical desktop-app release pipeline (Tauri or Wails). Generates .github/workflows/build-and-release.yml + .github/scripts/publish-release.sh so every push of a vX.Y.Z[-suffix] tag builds, signs, and uploads artifacts to DigitalOcean Spaces under the unified {channel}/v{VERSION}/ layout consumed by the Akira Billing endpoint. Triggers on "/desktop-release-setup", "setup desktop release", "tauri release pipeline", "wails release pipeline", "ship desktop app", "build and release desktop", "configure desktop CI release".
---

# Desktop release setup

Installs the standardized release pipeline inside a desktop app
repository (Tauri or Wails). Same layout for every app, regardless of
bundler.

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

### 2b. Pick OS targets

Ask the user which OS / arch combinations to build for. Multi-select.
Mention upfront that macOS runners on GitHub Actions cost 10x normal
minutes so unselect the ones you do not need.

```
Which targets? (space to toggle, enter to confirm)
  [x] macos-aarch64      Apple Silicon (recommended)
  [x] macos-x86_64       Intel Macs
  [ ] linux-x86_64       AppImage (Tauri) / tar.gz (Wails)
  [ ] windows-x86_64     MSI+NSIS (Tauri) / EXE+installer (Wails)
```

Default: both macOS targets only. Remember the chosen list — it drives
which build jobs end up in the rendered workflow and which `*_BUNDLE`
env vars the publish job exports.

### 3. Copy + render the workflow

Source files inside this skill:

- `templates/tauri-build-and-release.yml`     (base: header + macOS build jobs + publish)
- `templates/wails-build-and-release.yml`     (base: header + macOS build jobs + publish)
- `templates/publish-release.sh`
- `templates/snippets/tauri-linux-x86_64.yml`
- `templates/snippets/tauri-windows-x86_64.yml`
- `templates/snippets/wails-linux-amd64.yml`
- `templates/snippets/wails-windows-amd64.yml`

For the chosen bundler:

1. Read the matching base template file.
2. Replace the `env:` block values with the user-confirmed parameters.
3. If the user unselected `macos-aarch64` or `macos-x86_64`, remove the
   corresponding `build-aarch64:` / `build-x86_64:` job block.
4. For each non-mac target the user selected, append the matching
   `templates/snippets/{bundler}-{target}.yml` to the `jobs:` section
   above the `publish:` job.
5. Update the `publish:` job:
   - `needs: [build-aarch64, build-x86_64, build-linux-x86_64, build-windows-x86_64]`
     — keep only the jobs that were retained.
   - Drop any `*_BUNDLE` / `*_DMG` env line whose underlying build job
     was removed. Add `LINUX_APPIMAGE` / `WINDOWS_MSI` / `WINDOWS_NSIS`
     lines for the new targets, pointing at `dist/{artifact name}`.
     `publish-release.sh` already understands those env vars.
6. Write the rendered YAML to `.github/workflows/build-and-release.yml`
   in the target repo.
7. Copy `templates/publish-release.sh` verbatim to
   `.github/scripts/publish-release.sh` and `chmod +x` it.

If either destination already exists, show a diff and ask before
overwriting.

### 3b. (Optional) Nightly on demand

Ask the user "Add an on-demand nightly workflow? [y/N]". Default no —
nightly builds burn macOS minutes and most projects do not need them on
a schedule.

If yes, copy `templates/nightly-on-demand.yml` verbatim to
`.github/workflows/nightly-on-demand.yml`. It only triggers via
`workflow_dispatch` (manual run from the GitHub UI), computes a
`v{BASE}-nightly.{timestamp}` tag, and pushes it — which fires the main
release workflow. No `schedule:` block, no background cost.

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
