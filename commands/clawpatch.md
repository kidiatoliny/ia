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

## Step 7 — Linear sync preference + tracking model

GitHub issues always live in the **upstream repo** (where the code is). Linear issues live where the **team that does the work tracks effort** — and that is not always the same place. Before any issue creation, ask two questions:

### 7a — Sync to Linear at all?

```
sync findings to Linear too? (y/N)
- y: create Linear tracker(s), linked to GitHub
- n: GitHub only
```

If `n`: skip Linear entirely, proceed with only GitHub.

### 7b — Tracking model (only if Linear sync = yes)

Ask which model fits the upstream repo:

```
Where should the Linear tracker live?
  1) Library mode — Linear in the upstream project (e.g. "akira-io/laravel-sisp" → Linear project "laravel-sisp")
     Use when the upstream repo has its own dedicated team/maintainers tracking work directly.
  2) Consumer mode — Linear in the consumer product project (e.g. SISP findings → Linear project "nosferry.com")
     Use when the upstream repo is a library/SDK with no dedicated team; the consuming product's team does the fix work.
  3) Hybrid — primary tracker in upstream project, mirror trackers in consumer projects (blockedBy upstream)
     Use when multiple consumers care and the upstream has its own maintainers.
```

Cache the answer in `~/.claude/projects/<cwd-slug>/memory/linear-mapping.md` under `model:`. Future runs honour the cached choice without asking, unless the user says "remap".

### 7c — Linear target resolution

Resolve the project(s) based on the chosen model:

- **Library mode**: target = 1 project in the upstream team. Resolve via name match against the repo name.
- **Consumer mode**: target = 1 project in a consumer team. **Always ask** the user which consumer project owns this work — never auto-pick. List teams + projects so the user can choose. Cache the choice.
- **Hybrid**: target = 1 upstream project + 1..N consumer projects. Resolve upstream as in Library mode, then prompt for consumer projects as in Consumer mode.

Resolution algorithm (per target):

1. Get GitHub repo name: `gh repo view --json name -q .name`.
2. Query Linear teams: `mcp__linear__list_teams`.
3. For each team, list projects: `mcp__linear__list_projects`.
4. Match strategy (in order):
   - Cached mapping from `linear-mapping.md` (model + project per repo)
   - Project name exact match to repo name (Library mode only)
   - Project name kebab/space-normalized match
5. If single match found → confirm with user:
   ```
   Linear project: <Team>/<Project>. confirm? (Y/n)
   ```
6. If multiple candidates → present numbered menu, ask user to pick.
7. If zero matches → offer:
   ```
   No Linear project matches. options:
     1) map to an existing project (list)
     2) create new project "<name>" in team <T>
     3) skip Linear, GitHub only
   ```
   - Option 1: list all projects, user picks; save mapping.
   - Option 2: `mcp__linear__save_project` with name + team, then use it. **Confirm before creating** — never create projects without explicit user OK, especially in a team you don't already own findings in.
   - Option 3: fall back to GitHub-only mode.

## Step 8 — Prepare labels + milestone before any issue creation

Before opening any issue, materialise the labels and the milestone on both sides so every issue can be attached on creation (no second pass).

### 8a — Labels

Severity labels: `medium`, `low` (and `high`, `critical` if present in the report).
Category labels: take the exact `category:` strings from the report (`test-gap`, `build-release`, `bug`, `maintainability`, `data-loss`, etc.).

- **GitHub:** for each label needed, check `gh label list` and create with `gh label create <name> --color <hex> --description <text> --repo <owner/repo>` if missing. Use consistent colours (severity = warning hues, categories = neutral hues). Don't add a `clawpatch` label.
- **Linear:** for each label needed, check `mcp__linear__list_issue_labels` (filter by `team`); if missing, create with `mcp__linear__create_issue_label` scoped to the team (`teamId`). Linear has a workspace-level `Bug` that takes precedence over a team-level `bug` — match casing accordingly when applying.

### 8b — Milestone (GitHub + Linear project milestone)

Resolve a single milestone for the run. **Reuse before creating** — only open a new milestone when no existing open milestone fits the scope of this report.

**Best-fit search (run first):**

1. `gh api repos/<owner>/<repo>/milestones?state=open` and `mcp__linear__list_milestones` (filtered by the resolved Linear project).
2. Score each open milestone against the report:
   - Scope keyword overlap between milestone title/description and the dominant categories in the report (`bug`, `test-gap`, `build-release`, `maintainability`, etc.).
   - Release-version alignment: if `package.json` / `composer.json` / `CHANGELOG.md` indicates a next release `vX.Y.Z` and an open milestone targets that version, treat it as a strong match unless its description explicitly excludes audit findings.
   - Capacity sanity: skip milestones whose `due_on`/`targetDate` is < 7 days away or that are >80% complete — don't pile new findings onto a release that's about to ship.
3. Decision tree:
   - One strong match on both sides (GH + Linear) → confirm with the user (`Reuse milestone "<name>"? (Y/n)`) and use it.
   - Match exists on only one side → confirm reuse on the matching side, then create the missing side with the **same name + description + target date** to keep the pair mirrored.
   - Multiple plausible matches → numbered menu, user picks.
   - No plausible match → fall through to "Create new" below.
4. Cache the GH↔Linear milestone pair under `milestones:` in `~/.claude/projects/<cwd-slug>/memory/linear-mapping.md`. Future runs against the same release scope reuse the cached pair without re-prompting.

**Create new (only when best-fit yielded nothing):**

Always create with a **human-readable title that names the actual scope** — never `Milestone 1`, `Sprint 2`, `Findings`, etc.

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

## Step 8d — Duplicate guard (mandatory before any issue create)

Clawpatch reports often re-surface findings that already have open trackers from a prior run, an unrelated PR review, or a manually-filed bug. Never let those create duplicates.

For each parsed finding, before opening a new issue:

1. **GitHub search.**
   ```
   gh issue list --repo <owner>/<repo> --state all \
     --search "<finding-title-keywords> in:title,body" \
     --json number,title,state,url,milestone,labels
   ```
   - Include `state=all` — closed issues that match a re-occurring finding should be re-opened with a comment, not duplicated.
   - Also search by any file path / function name surfaced in the evidence block — those signals dedup better than fuzzy title overlap.
2. **Linear search.** `mcp__linear__list_issues` filtered by `team` + `project` with a title substring. Widen to closed states (`Done`, `Canceled`) only if the open-state search yields nothing.
3. **Per-finding decision:**
   - **Match found (open):** skip create, add a `gh issue comment` (or Linear comment via `mcp__linear__save_comment`) noting "Re-surfaced in clawpatch run <YYYY-MM-DD>" and attach the existing issue to the resolved milestone if it's not already there. Record as `skipped-duplicate` in the final report table.
   - **Match found (closed) and finding is identical:** re-open via `gh issue reopen <num>` (and move Linear state back via `save_issue`), comment with the new evidence, and re-attach to the run's milestone.
   - **No match:** proceed to Step 9 and create new.
4. Surface the dedup decisions inline as they happen so the user can override before any creates fire.

## Step 9 — Create issues

For each parsed finding (that survived the Step 8d dedup pass):

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

## Step 10 — Downstream consumer tracking (Hybrid mode only)

This step only runs when Step 7b selected **Hybrid** mode. In **Library** mode, the upstream project already owns the work and no consumer mirrors are needed. In **Consumer** mode, the Linear tracker is already in the consumer project, so no second tracker is needed either.

For Hybrid: after the upstream Linear trackers exist, mirror the relevant ones into each consumer project picked in Step 7c.

Reuse the consumer project(s) the user already picked in Step 7c — don't re-prompt. Then:

1. **Pick which findings to mirror.**
   - Default selection: all `bug` category findings and any finding with `triage: confirmed-bug`. Test-gaps and build-release nits do **not** propagate downstream by default.
   - Show the default list and let the user add/remove. If the user is unsure which findings affect the consumer, **ask** rather than guessing — most consumers only care about behavioural changes (bugs, breaking-API category, security-related).

2. **Create tracking issues in each consumer team/project.**
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

3. **Optionally create / extend a Linear Initiative for cross-team rollup.**
   - Ask: `Group upstream + consumer projects under a Linear Initiative for cross-team visibility? (y/N)`
   - If `y`: `mcp__linear__list_initiatives` to find a matching one (e.g. an existing "Payments platform" initiative). If none matches, ask for an initiative name + description and create with `mcp__linear__save_initiative`, then attach both upstream and consumer projects via `mcp__linear__save_project` with `addInitiatives`.

4. **Backlink upstream → downstream.**
   - For each upstream Linear issue that got a downstream tracker, append the tracker URL to the upstream issue via `save_issue` with `links: [{url: <downstream-url>, title: "Downstream: <team>/<project>"}]`. This makes the dependency visible from both sides.

If Library or Consumer mode was selected in Step 7b: skip this step entirely.

## Step 11 — Final report

Print a single table summarizing every issue created. Linear column omitted when sync was off.

```
clawpatch: <n> findings → <created> new, <skipped> duplicates, <reopened> re-opened
| # | severity | title | status         | github | linear | downstream |
|---|----------|-------|----------------|--------|--------|------------|
| 1 | high     | ...   | created        | #123   | NF-456 | FERRY-12   |
| 2 | medium   | ...   | dup-skipped    | #99    | NF-401 | —          |
| 3 | low      | ...   | reopened       | #57    | NF-310 | —          |
...
```

Always include the `status` column so the user can see which findings produced new tickets vs. mapped onto existing ones.

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
- Reuse before creating. Step 8b must search open GH milestones and Linear project milestones for a best-fit (scope keywords, release-version alignment, capacity sanity) and reuse with user confirmation before opening a new one. Only create a new milestone when no open milestone fits; cache the GH↔Linear pair in `linear-mapping.md` so subsequent runs converge on the same target.
- Always attach every run's issues to a milestone on both sides (GH + Linear project milestone). When creating a new milestone, the name must describe the actual scope (release version or descriptive phrase) — never `Milestone 1`, `Sprint N`, or other generic placeholders. Include a multi-paragraph description summarising scope, motivation, and exit criteria.
- Step 8d duplicate guard is mandatory and never bypassed. Every finding is searched against existing GH + Linear issues (open and closed) before any create. Open matches → comment + re-milestone, no new issue. Closed identical matches → re-open + comment. Only no-match findings reach Step 9.
- If the project has a clear next release version, the milestone name leads with that version (`vX.Y.Z — <scope>`); otherwise use a descriptive scope name with a date qualifier.
- Always set `dueDate` on Linear issues (tier by severity inside the milestone window) and pass `--milestone` to `gh issue create`. Never leave the target date empty.
- If the Linear team has cycles enabled, assign issues to current/next by severity. If cycles are disabled, surface this and proceed without — never silently skip without telling the user.
- Always ignore `/.clawpatch/` via `.gitignore` after init. The directory holds local audit state and reports and must never be committed.
- Cross-team dependencies (Step 10): never auto-create issues in another team's project without explicit user confirmation of (a) consumer team, (b) consumer project, (c) which findings to mirror. Cycles and milestones do NOT cross team boundaries — leave the downstream cycle/milestone for the consumer team to set. Always link with `blockedBy` upstream and backlink the upstream issue with the downstream URL so both sides see the dependency.
- When uncertain about downstream mapping, finding selection, or naming, **ask the user** rather than guessing. Better to ask once and cache the answer in `linear-mapping.md` than to silently create wrong-team issues.
- Tracking model is per-repo, not per-finding. Decide once (Step 7b: Library / Consumer / Hybrid), cache in `linear-mapping.md`, and apply uniformly to every finding in the run. GitHub issues always live in the upstream repo regardless of model — Linear placement is what changes.
- Consumer mode: the Linear tracker is the canonical work item; there is no separate "upstream" Linear issue. The GitHub issue in the upstream repo is the code-change record; the consumer Linear issue is the effort/scheduling record. Link them via Linear `links` (to the GH URL) and a `gh issue comment` (with the Linear URL).
- Library mode is appropriate only when the upstream repo has its own dedicated team in Linear that schedules and owns the work. If the repo is a library/SDK without dedicated maintainers (consumers do the fixes), default the user toward Consumer or Hybrid mode.
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
