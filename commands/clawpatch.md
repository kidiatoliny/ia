---
description: >-
  Run a full clawpatch review on the current project. Detects/installs the
  clawpatch CLI (bun > pnpm > npm), runs `clawpatch doctor` to verify the
  environment, initializes the project if needed, builds the feature map,
  executes `clawpatch review` with a user-chosen batch size (default 10),
  and turns the resulting report into linked GitHub + Linear issues so the
  user can review, comment, and merge fixes downstream.

  Trigger on: "/clawpatch", "run clawpatch", "clawpatch review", "audit with
  clawpatch", "automated code review".
argument-hint: "[batch-size]"
---

# /clawpatch

Reference: https://clawpatch.ai/#quickstart

End-to-end clawpatch workflow:

```
detect → install (if needed) → doctor → init (if needed) → map → review → report → issues (GH + Linear, linked)
```

## Step 1 — Detect / install CLI

Check `which clawpatch`. If missing, install in this order of preference:

1. `bun add -g clawpatch`
2. `pnpm add -g clawpatch`
3. `npm install -g clawpatch`

Use the first installer available on the system (`which bun`, `which pnpm`, `which npm`). Never silently skip; report which path was used.

## Step 2 — Doctor

Always run `clawpatch doctor --json` before any review work. Surface any failing checks to the user. Block until the environment is healthy or the user explicitly overrides ("skip doctor").

## Step 3 — Detect project state

In the project root, check whether clawpatch is already initialized:

- `.clawpatch/` directory present, OR
- `clawpatch status --json` returns a valid project payload (exit 0).

If initialized: do NOT re-run `clawpatch init`. Re-init wipes feature mapping state.

If not initialized: run `clawpatch init`, then `clawpatch map`.

If initialized but no map exists yet (status reports zero features), run `clawpatch map`.

After init (or before the first review on an already-initialised project), ensure `/.clawpatch/` is ignored by git. If a `.gitignore` exists and lacks `/.clawpatch/`, append it. If no `.gitignore` exists yet, create one with the entry. Never commit the `.clawpatch/` directory — it holds local audit artefacts (reports, state, locks).

## Step 4 — Pick batch size

Default `--jobs 10`. Ask the user to confirm or pick a different value:

```
clawpatch review batch size? default 10. higher = faster + more spend.
```

If the user pre-passed `$1` as argument, use it without asking.

## Step 5 — Review

Run:

```
clawpatch review --jobs <BATCH>
```

Stream output. On non-zero exit, surface error and stop — no issue creation on partial review.

## Step 6 — Report

Run `clawpatch report` and capture stdout. Parse the markdown report into structured issues:

- Section header `## <severity>: <title>` → issue title
- Block fields: `id:`, `category:`, `confidence:`, `triage:`, `status:`, `feature:`
- Body: evidence list, recommendation, test analysis, suggested regression test, minimum fix scope

Map severities: `critical|high|medium|low` → priority label and Linear priority (Urgent | High | Medium | Low).

## Step 7 — Linear sync preference

Before any issue creation, ask the user:

```
sync findings to Linear too? (y/N)
- y: create issue in both GitHub and Linear, linked
- n: GitHub only
```

If `n`: skip Linear entirely, proceed to Step 8 with only GitHub.

If `y`: resolve Linear target before creating any issue.

### Linear target resolution

1. Get GitHub repo name: `gh repo view --json name -q .name`.
2. Query Linear teams: `mcp__linear__list_teams`.
3. For each team, list projects: `mcp__linear__list_projects`.
4. Match strategy (in order):
   - Project name exact match to repo name (e.g. `nosferry.com` ↔ `nosferry.com`)
   - Project name kebab/space-normalized match (`nosferry-core` ↔ `nosferry core`)
   - User-supplied alias from a prior run (memory file `linear-mapping.md` if present)
5. If single match found → confirm with user:
   ```
   Linear project: <Team>/<Project>. confirm? (Y/n)
   ```
6. If multiple candidates → present numbered menu, ask user to pick.
7. If zero matches → offer two options:
   ```
   No Linear project matches "<repo>". options:
     1) map to an existing project (list)
     2) create new project "<repo>" in team <T>
     3) skip Linear, GitHub only
   ```
   - Option 1: list all projects, user picks; save mapping to `~/.claude/projects/<cwd-slug>/memory/linear-mapping.md` so future runs auto-resolve.
   - Option 2: `mcp__linear__save_project` with name=repo, team=picked, then use it.
   - Option 3: fall back to GitHub-only mode.

## Step 8 — Prepare labels + milestone before any issue creation

Before opening any issue, materialise the labels and the milestone on both sides so every issue can be attached on creation (no second pass).

### 8a — Labels

Severity labels: `medium`, `low` (and `high`, `critical` if present in the report).
Category labels: take the exact `category:` strings from the report (`test-gap`, `build-release`, `bug`, `maintainability`, `data-loss`, etc.).

- **GitHub:** for each label needed, check `gh label list` and create with `gh label create <name> --color <hex> --description <text> --repo <owner/repo>` if missing. Use consistent colours (severity = warning hues, categories = neutral hues). Don't add a `clawpatch` label.
- **Linear:** for each label needed, check `mcp__linear__list_issue_labels` (filter by `team`); if missing, create with `mcp__linear__create_issue_label` scoped to the team (`teamId`). Linear has a workspace-level `Bug` that takes precedence over a team-level `bug` — match casing accordingly when applying.

### 8b — Milestone (GitHub + Linear project milestone)

Always create a single milestone for the run, with a **human-readable title that names the actual scope** — never `Milestone 1`, `Sprint 2`, `Findings`, etc.

Naming rule:
- If the package has a current version in `package.json` / `composer.json` / `CHANGELOG.md` and the findings would naturally bundle into the next release, name the milestone for that release: `vX.Y.Z — <short scope phrase>` (e.g. `v0.7.0 — Payment correctness and test reliability hardening`).
- Otherwise, name it for the scope: `<scope phrase> (<date>)` (e.g. `Auth middleware hardening (2026-Q2)`).

Description (markdown, multi-paragraph) must summarise:
- Which findings are bundled (counts by category and any confirmed bugs called out by Linear/GH ID)
- Why these matter as a unit (release-blocking, compliance, etc.)
- Exit criteria (e.g. "Ships as vX.Y.Z once all linked issues are closed")

Target date: pick a realistic horizon — default 4–6 weeks out, or align with a known release date if one is in scope.

- GitHub: `gh api -X POST repos/<owner>/<repo>/milestones -f title=… -f description=… -f due_on=…Z`. Capture the milestone number.
- Linear: `mcp__linear__save_milestone` with `project`, `name`, `description`, `targetDate`. Capture the milestone ID/name.

### 8c — Linear cycles

`mcp__linear__list_cycles` for the target team:
- If cycles exist, assign issues by severity:
  - `critical` / `high` / `medium` → current cycle (or earliest upcoming if none is current yet)
  - `low` → next cycle
- If the team has no cycles enabled, surface a note to the user — Linear MCP has no `save_cycle`; the user must enable cycles in Linear's team settings. Then either retry the cycle step or proceed without it (user's choice).
- If the team uses Triage, leave the issue status default (Linear places new issues into Triage automatically when enabled). Do not force a status override.

## Step 9 — Create issues

For each parsed finding:

1. **Create GitHub issue first** (always, regardless of Linear choice):

   ```
   gh issue create \
     --title "<title>" \
     --body "<formatted body>" \
     --label "<severity>,<category>" \
     --milestone "<milestone title>"
   ```

   Title rules:
   - Use the bare finding title — do NOT prefix with `<severity>:` or any other tag. Severity lives on the label, not the title.

   Labels:
   - Pass severity and category as labels (e.g. `medium,test-gap`). Do NOT add a `clawpatch` label.
   - Labels must already exist (created in Step 8a).

   Milestone: attach the milestone created in Step 8b.

   Body must include ONLY (no metadata header, no severity/category/triage/confidence/feature/clawpatch-id lines, no "Generated by clawpatch" footer):
   - `## Evidence` — file:line list
   - `## Recommendation`
   - `## Test analysis`
   - `## Suggested regression test`
   - `## Minimum fix scope`
   - `## Repro` (only if present in the report)

   Metadata such as severity, category, triage, confidence, and clawpatch id belong on labels/properties (and the issue tracker's own URL), NOT in the body.

2. **If Linear sync = yes**, create Linear issue referencing GitHub URL:

   - `mcp__linear__save_issue` with:
     - `team`, `project`, `title` (bare title, no `<severity>:` prefix), `description` (same body shape as above — no metadata header)
     - `priority` (from severity mapping: critical/urgent=1, high=2, medium=3, low=4)
     - `assignee: "me"` (always assign to the invoking user)
     - `labels: ["<category>"]` (must exist from Step 8a; no `clawpatch` label)
     - `milestone: "<milestone name>"` (from Step 8b)
     - `dueDate: "YYYY-MM-DD"` (tier by severity: medium ≈ milestone target − 2 weeks, low ≈ milestone target)
     - `cycle: "<cycle name or id>"` (only if Step 8c found cycles)
   - Attach the GitHub URL via `links: [{url, title}]`.

3. **If Linear created**, backlink GitHub → Linear:

   ```
   gh issue comment <gh-number> --body "Linked Linear: <linear-url>"
   ```

Rate-limit awareness: if creating >20 issues, pause briefly between calls.

## Step 10 — Downstream consumer tracking (cross-team dependencies)

After the upstream issues exist, ask the user whether any **other Linear teams** own projects that consume this code (e.g. a frontend app that depends on a SISP SDK, or a mobile app that depends on a payments package).

Prompt verbatim:

```
Do other Linear teams have projects that depend on this code? (y/N)
- y: I'll mirror selected findings as tracking issues in those teams, linked with `blockedBy` to the upstream AKIRA-N.
- n: skip.
```

If `y`:

1. **Discover consumer teams/projects.**
   - `mcp__linear__list_teams` (exclude the upstream team already used).
   - For each candidate team the user names, list projects via `mcp__linear__list_projects` (filter by team).
   - Ask the user to pick the consumer project(s) — never guess. If unclear, **ask** which projects depend on the upstream package. Persist the mapping in `~/.claude/projects/<cwd-slug>/memory/linear-mapping.md` under a `downstream:` section so future runs can pre-populate the choice.

2. **Pick which findings to mirror.**
   - Default selection: all `bug` category findings and any finding with `triage: confirmed-bug`. Test-gaps and build-release nits do **not** propagate downstream by default.
   - Show the default list and let the user add/remove. If the user is unsure which findings affect the consumer, **ask** rather than guessing — most consumers only care about behavioural changes (bugs, breaking-API category, security-related).

3. **Create tracking issues in each consumer team/project.**
   - One tracking issue per (consumer-project, upstream-finding) pair.
   - `mcp__linear__save_issue` with:
     - `team`: consumer team
     - `project`: consumer project
     - `title`: `Integrate fix: <upstream title>` (or `Pick up <upstream-package> fix: <upstream title>` — pick the phrasing that reads naturally for the consumer team; **ask** if uncertain)
     - `description`: short brief naming the upstream package, the user-visible symptom in the consumer, and the link to the upstream Linear + GitHub issues. Do not copy the full upstream body.
     - `priority`: same priority as upstream
     - `assignee`: leave unset unless the consumer team has an obvious owner the user names — **ask** rather than auto-assigning across team boundaries
     - `labels`: only `<upstream-category>` if the consumer team has that label; otherwise omit. Do not create labels in another team without asking.
     - `blockedBy: ["<upstream-linear-id>"]` (e.g. `["AKIRA-104"]`) — this is the cross-team dependency edge.
     - `links: [{url: <upstream-gh-url>, title: "Upstream GH"}, {url: <upstream-linear-url>, title: "Upstream Linear"}]`
   - Do **not** assign these to the upstream milestone or the upstream cycle — the consumer team has its own milestone/cycle and the user picks (or skips) those separately. Ask the user whether to set a `dueDate` keyed off the upstream milestone's target date.

4. **Optionally create / extend a Linear Initiative for cross-team rollup.**
   - Ask: `Group upstream + consumer projects under a Linear Initiative for cross-team visibility? (y/N)`
   - If `y`: `mcp__linear__list_initiatives` to find a matching one (e.g. an existing "Payments platform" initiative). If none matches, ask for an initiative name + description and create with `mcp__linear__save_initiative`, then attach both upstream and consumer projects via `mcp__linear__save_project` with `addInitiatives`.

5. **Backlink upstream → downstream.**
   - For each upstream Linear issue that got a downstream tracker, append the tracker URL to the upstream issue via `save_issue` with `links: [{url: <downstream-url>, title: "Downstream: <team>/<project>"}]`. This makes the dependency visible from both sides.

If `n` or no other teams are relevant: skip silently and proceed to the final report.

## Step 11 — Final report

Print a single table summarizing every issue created. Linear column omitted when sync was off.

```
clawpatch: <n> findings → issues created
| # | severity | title | github | linear | downstream |
|---|----------|-------|--------|--------|------------|
| 1 | high     | ...   | #123   | NF-456 | FERRY-12, FERRY-13 |
| 2 | medium   | ...   | #124   | NF-457 | — |
...
```

The `downstream` column is omitted when Step 10 was skipped.

## Rules

- Never re-run `clawpatch init` on an already-initialized project.
- Always run `clawpatch doctor` before any review.
- Never silently install a global package without telling the user which package manager was used.
- Never create Linear issues without GitHub backing (or vice versa) unless the user explicitly opts for single-side.
- Never invent severity, category, or evidence — every issue mirrors the clawpatch report exactly.
- Never put severity/category/triage/confidence/clawpatch-id/feature in the issue body. They belong on labels (GH) and properties (Linear). The body is Evidence + Recommendation + Test analysis + Suggested regression test + Minimum fix scope + Repro only.
- Never prefix the issue title with the severity (no `medium:` / `low:`). The severity label carries that signal.
- Never add a `clawpatch` label. Severity + category labels are enough.
- Never append a `Generated by clawpatch.` footer to issue bodies.
- Always set `assignee: "me"` on Linear issues so they land on the invoking user's plate.
- Always create labels (GH + Linear) before opening issues if they don't exist. Never silently skip an unknown label — opening with a missing label drops the label.
- Always create a milestone (GH + Linear project milestone) and attach every run's issues to it. Milestone name must describe the actual scope (release version or descriptive phrase) — never `Milestone 1`, `Sprint N`, or other generic placeholders. Include a multi-paragraph description summarising scope, motivation, and exit criteria.
- If the project has a clear next release version, the milestone name leads with that version (`vX.Y.Z — <scope>`); otherwise use a descriptive scope name with a date qualifier.
- Always set `dueDate` on Linear issues (tier by severity inside the milestone window) and pass `--milestone` to `gh issue create`. Never leave the target date empty.
- If the Linear team has cycles enabled, assign issues to current/next by severity. If cycles are disabled, surface this and proceed without — never silently skip without telling the user.
- Always ignore `/.clawpatch/` via `.gitignore` after init. The directory holds local audit state and reports and must never be committed.
- Cross-team dependencies (Step 10): never auto-create issues in another team's project without explicit user confirmation of (a) consumer team, (b) consumer project, (c) which findings to mirror. Cycles and milestones do NOT cross team boundaries — leave the downstream cycle/milestone for the consumer team to set. Always link with `blockedBy` upstream and backlink the upstream issue with the downstream URL so both sides see the dependency.
- When uncertain about downstream mapping, finding selection, or naming, **ask the user** rather than guessing. Better to ask once and cache the answer in `linear-mapping.md` than to silently create wrong-team issues.
- If the user says "skip issues" or "report only", stop after Step 6 and print the report instead of creating issues.
- If the report has zero findings, print "clawpatch: no findings" and exit cleanly — do not create empty issues.

## Exceptions

User-authorized phrases:

- "skip doctor" — bypass Step 2.
- "force init" — re-run init even if already initialized (destructive — confirm twice).
- "report only" / "skip issues" — produce report, no issues.
- "linear only" / "github only" — single-side issue creation.

## Caveats

- Linear MCP only required when user opts into Linear sync. If they say no, skip the MCP entirely.
- If user said yes and `mcp__linear__list_teams` errors, surface the connection instructions and ask whether to fall back to GitHub-only or abort.
- GitHub CLI must be authenticated (`gh auth status`). Surface and stop if not.
- Mapping cache: when user picks or creates a Linear project, persist `repo → team/project` to `~/.claude/projects/<cwd-slug>/memory/linear-mapping.md` so future runs auto-resolve without asking.
