# Release Flow

Releases are automated. There are two pipelines, both driven by conventional
commits and `cliff.toml`.

## 1. CHANGELOG refresh (every push to `main`)

The `changelog` workflow runs on every push to `main`. It uses
[`git-cliff`](https://git-cliff.org) to regenerate the `## [Unreleased]`
block at the top of `CHANGELOG.md` from conventional commit messages
since the last `vX.Y.Z` tag.

If the regenerated block differs from what is already in the file, the
workflow opens a pull request titled `chore(changelog): refresh unreleased
section`. A human reviewer reads the bullets, tightens them so they sound
natural rather than mechanical, and merges.

That makes `## [Unreleased]` the **human-voice changelog**: a curated,
readable summary of what is coming in the next release. The bot writes a
draft; a human ships the final wording.

## 2. Release (every `vX.Y.Z` tag push)

The `release` workflow runs when a tag matching `v[0-9]+.[0-9]+.[0-9]+`
(or a prerelease suffix like `-rc.1`) is pushed. It:

1. Runs `go test ./...`.
2. Generates **technical release notes** from `git-cliff` for the commit
   range bounded by the new tag. These notes are exhaustive and faithful
   to the commit log — they are not the same as the human-voice CHANGELOG.
3. Builds a source archive (`desktopkit-vX.Y.Z.tar.gz`).
4. Produces a coverage report (`coverage-vX.Y.Z.txt`).
5. Publishes a GitHub Release at the tag with the technical notes as the
   body and the artifacts attached.

## How the two voices coexist

| Surface | Voice | Audience |
| --- | --- | --- |
| `CHANGELOG.md` | Human, curated, succinct | Library users browsing history |
| GitHub Release body | Technical, exhaustive | Downstream maintainers diffing versions |
| Git tags + commits | Conventional commits | Tooling and bots |

The CHANGELOG is the polished story; the GitHub Release is the audit log.

## Cutting a release

1. Make sure `## [Unreleased]` reads cleanly. Edit prose if the bot's
   first draft is awkward.
2. Bump the version in the unreleased header — change `## [Unreleased]`
   to `## [X.Y.Z] - YYYY-MM-DD`, and start a fresh empty
   `## [Unreleased]` above it.
3. Commit the change with `chore(release): vX.Y.Z`.
4. Tag and push:
   ```
   git tag vX.Y.Z
   git push origin main vX.Y.Z
   ```
5. The release workflow publishes the GitHub Release automatically.

## Conventional commit map

`cliff.toml` groups commits into sections by prefix:

| Prefix | CHANGELOG section |
| --- | --- |
| `feat`, `add` | Added |
| `fix` | Fixed |
| `refactor` | Changed |
| `perf` | Improved |
| `revert` | Reverted |
| `docs` | Documentation |
| `chore(deps)` | Dependencies |
| `style`, `test`, `chore` (other), `ci` | hidden |

Anything not matching a parser rule is dropped. Use the right prefix or
your change will not appear in the changelog.
