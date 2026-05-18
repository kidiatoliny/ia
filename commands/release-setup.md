---
name: release-setup
description: >-
  Installs an automated CHANGELOG + GitHub Release pipeline as a GitHub
  Action so pushing a vX.Y.Z tag regenerates CHANGELOG.md (conventional-
  changelog angular preset), commits it back to the release branch, and
  publishes the GitHub Release. Detects the project language (PHP,
  JavaScript/TypeScript, Rust, Go, Python), wires the matching test
  command into the action as a pre-release gate, optionally bumps the
  manifest version for npm/Cargo projects, and offers to remove
  pre-existing release tooling (release-it, standard-version,
  semantic-release). Identifies the default branch via the GitHub API
  and asks the user to confirm which branch holds releases. Triggers on
  "release setup", "automate changelog", "remove release-it", "ship via
  tag", "release pipeline", "/release-setup".
---

# release-setup

Installs a tag-driven release pipeline. After install, the release flow is:

```
git tag vX.Y.Z
git push --follow-tags
```

GitHub Action regenerates `CHANGELOG.md`, commits it to the release branch, and creates the GitHub Release.

## When this fires

- User says: "release setup", "automate changelog", "remove release-it", "/release-setup".
- User mentions wanting GH Action to handle CHANGELOG on tag.
- User asks to replace release-it / standard-version / semantic-release with native GH Actions.

## What it produces

1. `.github/workflows/release.yml` — tag-triggered pipeline
2. Removes pre-existing release tool config + dependencies (with user confirmation)
3. Reports the new flow + any required secrets

## Run order

```
1. Detect repo state            — gh remote, default branch, current branch
2. Pick release branch          — show candidates, ask user (default = repo default)
3. Detect language              — composer.json / package.json / Cargo.toml / go.mod / pyproject.toml
4. Detect existing release tool — release-it (.release-it*, scripts), standard-version, semantic-release
5. Pick changelog preset        — default `angular`; ask if user wants to deviate
6. Decide test gate             — default ON; resolve test command from language adapter
7. Decide manifest version bump — npm/cargo → ask; PHP/Go/Python → skip unless asked
8. Branch protection check      — gh api repos/.../branches/<release>/protection; warn if push restricted
9. Render workflow              — workflows/release.yml.tmpl with substitutions
10. Write file                  — abort if exists unless user confirms overwrite
11. Remove old tool             — only with user confirmation; show removed lines
12. Verify                      — workflow YAML lint via `gh workflow view` or `actionlint` if available
13. Report                      — flow, secrets needed, first-tag suggestion
```

## Branch detection

NEVER assume the default branch. Always query:

```
gh api repos/{owner}/{repo} --jq .default_branch
```

Then list remote branches:

```
git ls-remote --heads origin | awk '{print $2}' | sed 's|refs/heads/||'
```

Present the list with the default pre-selected. The user picks.

## Language adapters

Each adapter defines: manifest file, test command, version-bump strategy.

| Language    | Manifest          | Test command          | Bump manifest? |
|-------------|-------------------|-----------------------|----------------|
| PHP         | composer.json     | `composer test`       | no             |
| JS/TS       | package.json      | `npm test` / `pnpm test` | yes        |
| Rust        | Cargo.toml        | `cargo test`          | yes            |
| Go          | go.mod            | `go test ./...`       | no             |
| Python      | pyproject.toml    | `pytest`              | optional       |

If an adapter file exists at `references/languages/<lang>.md`, read it first — it overrides this table.

For PHP and Go, version lives in git tags. Composer/Go resolve from tags directly. Do not write a version to the manifest.

For npm/Cargo, ask the user whether to bump the manifest field. Default off; offer on. If on, action writes the tag's version (stripped `v`) into `package.json`/`Cargo.toml` before committing CHANGELOG.

## Workflow template

`workflows/release.yml.tmpl` is the canonical output. Substitutions:

- `{{RELEASE_BRANCH}}` — picked branch
- `{{TEST_COMMAND}}` — language test command (or removed if gate off)
- `{{LANG_SETUP_STEPS}}` — language-specific runtime setup
- `{{MANIFEST_BUMP_STEPS}}` — version bump steps (or removed)
- `{{CHANGELOG_PRESET}}` — `angular` by default

Permissions block always includes `contents: write`. If branch protection requires PR, instruct the user to set `RELEASE_PAT` secret + adjust checkout `token:`.

## Old-tool removal

Detect and confirm before removing:

| Tool             | Files                                                           |
|------------------|-----------------------------------------------------------------|
| release-it       | `.release-it.*`, `package.json` scripts `release/release:dry/release:ci`, devDeps `release-it`, `@release-it/conventional-changelog` |
| standard-version | `.versionrc*`, `package.json` script `release`, devDep `standard-version` |
| semantic-release | `.releaserc*`, `release.config.*`, devDep `semantic-release`    |

Show every line that will be removed. Ask. Never silent-delete.

## Branch protection

```
gh api repos/{owner}/{repo}/branches/{branch}/protection 2>/dev/null
```

If protection requires PR for pushes:

> Branch `{{RELEASE_BRANCH}}` has push restrictions. The default `GITHUB_TOKEN` cannot bypass them. Create a PAT with `contents:write`, store as repo secret `RELEASE_PAT`, and the workflow will use it.

Then patch the checkout step to use `token: ${{ secrets.RELEASE_PAT }}`.

## Idempotency

If `.github/workflows/release.yml` exists:

1. Show diff vs template.
2. Ask: overwrite / skip / merge-manually.
3. Never silently overwrite.

## Verification

After writing the workflow, validate YAML:

```
gh workflow view release.yml 2>/dev/null
```

Or, if `actionlint` is available locally:

```
actionlint .github/workflows/release.yml
```

Report any lint failures to the user before declaring done.

## Output discipline

- Terse, technical.
- No emojis.
- Final report: what was added, what was removed, secrets needed, first-tag command.
- Single fenced block:

```
release-setup: complete
- workflow: .github/workflows/release.yml
- release branch: {{RELEASE_BRANCH}}
- language: {{LANG}}
- test gate: {{ON|OFF}}
- removed: {{OLD_TOOL_OR_NONE}}
- secrets needed: {{NONE|RELEASE_PAT}}
- next step: git tag v<X.Y.Z> && git push --follow-tags
```

## Exceptions

User may explicitly opt out of any step. Phrases:

- "skip test gate"
- "keep release-it"
- "don't touch the branch"
- "no manifest bump"

Authorization scoped to this run only.
