---
name: milestone-branch
description: |
  Professional milestone-branch Git workflow. Enforces: never commit to main; each milestone gets an integration branch (milestone/vX.Y.Z); feature branches fork from the milestone branch; PRs always target the milestone branch; the milestone branch merges to main only when the whole milestone is tested and complete. GitHub Actions enforce these rules even when working outside Claude.

  Use this skill whenever the user says any of: /start-issue, /finish-milestone, /setup-branch-policy, "start issue", "iniciar issue", "trabalhar no issue", "fechar milestone", "merge milestone", "configurar branch protection", "setup milestone workflow", "criar branch para issue", "começar a trabalhar no". Also trigger proactively when the user is about to work on a Linear issue and no feature branch has been created yet — don't wait to be asked.
---

# Milestone-Branch Workflow

## Mental model

```
main  (stable — only receives PRs from milestone/* branches)
 └── milestone/v1.0.0-beta   (integration branch for the milestone)
       ├── feat/AKIRA-150-billing-ux
       ├── feat/AKIRA-154-ci-matrix
       └── fix/AKIRA-156-sentry-scrubber
 └── milestone/v1.1.0-multi-framework
       └── feat/AKIRA-162-symfony-driver
```

Feature branches → milestone branch → main. Never skip a level.

---

## /start-issue <LINEAR-ID>

Start working on a Linear issue. Creates branches, updates Linear, installs branch policy on first use.

**Steps:**

1. **Resolve repo** — `gh repo view --json nameWithOwner` to get `owner/repo`.

2. **Fetch the issue** — `mcp__linear__get_issue` with the given ID (e.g. `AKIRA-150`).
   Extract: `title`, `projectMilestone.name`, `gitBranchName`, `url`.

3. **Derive milestone branch name** — extract the semver prefix from the milestone title:
   - `"v1.0.0-beta — Public beta"` → `milestone/v1.0.0-beta`
   - `"v1.1.0 — Multi-framework + diff mode"` → `milestone/v1.1.0`
   Rule: take everything up to the first ` — ` (em dash with spaces), lowercase, strip non-semver chars.

4. **Derive feature branch name** — prefer Linear's `gitBranchName` field (already slug-formatted by Linear, e.g. `akira-150-billing-ux`), prefix with `feat/`:
   → `feat/akira-150-billing-ux`
   If `gitBranchName` is absent, derive from title: lowercase, kebab-case, max 50 chars.

5. **Ensure milestone branch exists:**
   ```bash
   git ls-remote --heads origin milestone/vX.Y.Z
   ```
   If empty → create it from main:
   ```bash
   git fetch origin
   git checkout main && git pull origin main
   git checkout -b milestone/vX.Y.Z
   git push -u origin milestone/vX.Y.Z
   ```

6. **Create feature branch from milestone branch:**
   ```bash
   git fetch origin
   git checkout milestone/vX.Y.Z && git pull origin milestone/vX.Y.Z
   git checkout -b feat/AKIRA-NNN-slug
   git push -u origin feat/AKIRA-NNN-slug
   ```

7. **Update Linear issue to In Progress** — `mcp__linear__save_issue` with `{ id, status: "In Progress" }`.

8. **Comment on the Linear issue** — `mcp__linear__save_comment`:
   > Branch: `feat/AKIRA-NNN-slug` — targets `milestone/vX.Y.Z`

9. **Install branch policy if missing** — check if `.github/workflows/branch-policy.yml` exists in the repo root. If not, run `/setup-branch-policy` now (it's idempotent).

10. **Report** — tell the user: current branch, milestone branch, Linear URL. They're ready to code.

**If Linear MCP is unavailable:** ask the user for milestone name and issue slug, skip steps 2, 7, 8, continue with git steps.

---

## /setup-branch-policy

Idempotent. Installs GitHub Actions + branch protection rules so the workflow is enforced even outside Claude. Run once per repo (automatically called by `/start-issue` when missing).

**Step 1 — Create `.github/workflows/branch-policy.yml`:**

Write this file to the repo root (create `.github/workflows/` dir if needed):

```yaml
name: Branch Policy

on:
  pull_request:
    types: [opened, synchronize, reopened, edited]

jobs:
  enforce-targets:
    name: Enforce branch targets
    runs-on: ubuntu-latest
    steps:
      - name: Check PR base branch rules
        run: |
          BASE="${{ github.base_ref }}"
          HEAD="${{ github.head_ref }}"
          echo "PR: $HEAD → $BASE"

          # feat/fix/chore/docs/refactor/test branches must target milestone/*
          if [[ "$HEAD" =~ ^(feat|fix|chore|docs|refactor|test)/ ]]; then
            if [[ "$BASE" == "main" || "$BASE" == "master" ]]; then
              echo "::error::Feature/fix branches must target a milestone/* branch, not '$BASE'."
              echo "::error::Retarget this PR to the appropriate milestone/* branch."
              exit 1
            fi
            if [[ ! "$BASE" =~ ^milestone/ ]]; then
              echo "::error::Branch '$HEAD' must target a milestone/* branch. Got: '$BASE'"
              exit 1
            fi
          fi

          # milestone/* branches must target main (or master)
          if [[ "$HEAD" =~ ^milestone/ ]]; then
            if [[ "$BASE" != "main" && "$BASE" != "master" ]]; then
              echo "::error::Milestone branches must merge into main. Got base: '$BASE'"
              exit 1
            fi
          fi

          echo "Branch policy OK: $HEAD → $BASE"
```

**Step 2 — Apply GitHub branch protection to `main`:**

```bash
gh api repos/{owner}/{repo}/branches/main/protection \
  -X PUT \
  -H "Accept: application/vnd.github+json" \
  --input - <<'JSON'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["Enforce branch targets"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
```

Note: `contexts` must match the job `name:` field in the YAML above (`"Enforce branch targets"`).

**Step 3 — Commit and push the workflow file:**

```bash
git add .github/workflows/branch-policy.yml
git commit -m "ci: add branch policy enforcement workflow"
git push
```

Push to whatever branch is currently checked out (feature branch or milestone branch — not main directly).

**Step 4 — Report** — tell the user the policy is live, what it enforces, and that it applies to all future PRs.

---

## /finish-milestone <vX.Y.Z>

Close a milestone: verify all issues are done, open the merge PR.

**Steps:**

1. **Fetch milestone issues** — `mcp__linear__list_issues` filtered by project + milestone name.
   Check each issue's `status`. If any are not `Done` or `Cancelled`, list them and ask the user to confirm before continuing.

2. **Update local milestone branch:**
   ```bash
   git fetch origin
   git checkout milestone/vX.Y.Z && git pull origin milestone/vX.Y.Z
   ```

3. **Open the merge PR:**
   ```bash
   gh pr create \
     --base main \
     --head milestone/vX.Y.Z \
     --title "Release milestone/vX.Y.Z" \
     --body "$(cat <<'EOF'
   ## Milestone vX.Y.Z

   All issues in this milestone are complete. This PR merges the integration branch into main.

   Merge only after CI passes. After merge, tag the release:
   \`\`\`
   git tag vX.Y.Z main
   git push origin vX.Y.Z
   \`\`\`
   EOF
   )"
   ```

4. **Report** — PR URL, reminder to merge after CI green, reminder to tag.

---

## Branch naming rules (summary)

| Branch type       | Pattern                        | Branches from      | PRs target         |
|-------------------|--------------------------------|--------------------|--------------------|
| Milestone branch  | `milestone/vX.Y.Z`             | `main`             | `main`             |
| Feature branch    | `feat/AKIRA-NNN-slug`          | `milestone/vX.Y.Z` | `milestone/vX.Y.Z` |
| Bug fix branch    | `fix/AKIRA-NNN-slug`           | `milestone/vX.Y.Z` | `milestone/vX.Y.Z` |
| Chore/docs/etc.   | `chore/…`, `docs/…`, `test/…`  | `milestone/vX.Y.Z` | `milestone/vX.Y.Z` |

---

## Edge cases

- **Issue has no milestone in Linear** — ask the user which milestone it belongs to before proceeding.
- **Already on the right branch** — skip branch creation, just report status.
- **milestone branch already exists remotely** — skip creation, just checkout and pull.
- **Multiple repos, no git context** — ask user for `owner/repo` explicitly.
- **Linear credits exhausted** — proceed with git steps only, ask user for milestone name and slug manually.
