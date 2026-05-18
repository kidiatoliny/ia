---
name: commit-guard
description: >-
  Mandatory pre-commit and pre-push code quality gate. Enforces SOLID, DRY,
  KISS, language-idiomatic naming, file-size cap (300 lines), comment policy,
  test coverage on every change, dead-code removal, breaking-change discipline,
  AI-tells ban, and secrets scan across any language. Triggers on commit/push
  intent verbs ("commit", "push", "ship", "create PR", "merge", "release",
  "/commit-guard"), and proactively before any tool call that would create a
  git commit or push. Reads referenced rules from references/ first. Blocks
  on violations; never auto-fixes destructive issues without confirmation.
  Language adapters: Go, PHP/Laravel (no laravel-boost dependency), TypeScript
  /React, Python, Rust, Ruby — and any new language follows community-standard
  conventions verified against authoritative sources, never invented.
---

# commit-guard

Mandatory quality gate before every commit and push. Rules are non-negotiable unless the user explicitly authorizes an exception for that specific change.

## When this fires

- User says: "commit", "push", "ship it", "create PR", "merge", "release", "/commit-guard".
- BEFORE invoking `git commit`, `git push`, `gh pr create`, `gh release create`, or any equivalent tool.
- After significant code edits when about to summarize "done" — surface validation status first.

If you skip running this and commit anyway, you violated the user's explicit instruction. Do not skip.

## Source of truth

Always read first:

1. `references/00-rules.md` — consolidated mandatory rules (all languages)
2. `references/01-naming-conventions.md` — language-idiomatic naming
3. `references/02-comments-policy.md` — strict comment policy
4. `references/03-ai-tells.md` — banned tokens/phrasings
5. `references/languages/<detected-lang>.md` — language-specific checks
6. Project root `CLAUDE.md` (if present) — project-specific overrides

If a project file overrides a rule, the project wins. If user explicitly authorizes an exception in the current turn, that exception applies to the current change only.

## The 10 mandatory rules

1. **File length** — hard cap 300 lines per source file. Block above.
2. **Tests** — every functional change ships tests (new or updated). Block if missing.
3. **Commit scopes** — conventional commits `type(scope): description`. Scopes must come from the project's established set; if undefined, analyze the repo and define a scope set before first commit (never invent ad-hoc).
4. **Naming** — follow community-standard convention for the language. If the project lacks a convention, derive it from the language community (PEP 8, gofmt, PSR-12, Airbnb/TS-style, RuboCop, etc.). Never invent.
5. **Pre-push** — always run full build + lint + test before push. Block on any failure.
6. **Comments** — strict. No narrative, no docblocks summarizing what code does, no section dividers, no obvious-code comments. Allowed only: static-analysis annotations (PHPDoc for PHPStan, TSDoc for generics, GoDoc on exported symbols), `// TODO(@handle):` one-liners, ≤1-line non-obvious-logic notes.
7. **AI tells** — block emojis in code/copy/UI, em-dash in prose (`—`), AI-shaped phrasings ("in today's fast-paced world", "moreover", "furthermore", "additionally", "delve into", "leverage" as filler). Override only when user explicitly authorizes for the specific change.
8. **Secrets scan** — scan staged diff for credentials, API keys, private keys, `.env` contents, hardcoded tokens. On ambiguity, ASK before proceeding, explaining the suspicious match clearly. Never proceed silently when uncertain.
9. **Dead code** — every unused import, variable, function, type, file detected must be removed. Explain the impact of each removal in the report (callers, references, public-API status).
10. **Breaking changes** — any change to a public API surface requires major-version bump + CHANGELOG entry under `Changed` or `Removed`. Explain to the user what breaks, who depends on it (best-effort scan), and the migration path.

These rules are MANDATORY. They are not preferences. They are not skippable to "ship faster". They are not "noisy". They are the agreement.

## Enforcement hook

A `PreToolUse` hook in `~/.claude/settings.json` intercepts every Bash
tool call matching `git commit`, `git push`, `gh pr create`, or
`gh release create`. The hook blocks the call until a marker file at
`$TMPDIR/commit-guard/ok` is present and fresh (< 5 minutes old).

After the skill finishes its run and decides to allow the commit/push
(either because everything passed or because the user explicitly
authorized exceptions), it MUST touch the marker:

```
mkdir -p "${TMPDIR:-/tmp}/commit-guard"
touch "${TMPDIR:-/tmp}/commit-guard/ok"
```

The hook consumes (removes) the marker after one successful pass-through,
so each commit/push requires a fresh skill run. This is the enforcement
mechanism — the rule is not "please remember to run", it is the harness
blocking direct git commands until the skill says OK.

## Run order

```
1. Detect language(s)              — from staged file extensions
2. Read references                 — 00 + 01 + 02 + 03 + languages/<lang>
3. File-length scan                — every staged source file ≤ 300 lines
4. Comment-policy scan             — banned patterns + obvious-code
5. AI-tells scan                   — emojis, em-dashes, banned phrasings
6. Naming-convention scan          — symbols match language standard
7. Dead-code scan                  — unused imports/vars/funcs
8. Secrets scan                    — staged diff
9. Test presence scan              — every modified source has matching test changes
10. Breaking-change detection      — public API diff vs last tag/main
11. Language build/lint/test       — full, blocking on any failure (pre-push only;
                                     pre-commit runs the cheap subset).
                                     For Laravel projects: MUST execute `composer test`
                                     (or the equivalent full composite script). A green
                                     filtered run is NOT a substitute. No marker unlock
                                     until the full script passes or user authorizes a
                                     specific pre-existing failure via the 4-step protocol
                                     in languages/php.md.
12. Commit-message validation      — conventional format + project scope set
13. Report                         — one consolidated violation table
14. Decision gate                  — block if any rule fails; allow only on
                                     explicit user authorization for that change
15. Unlock marker                  — on allow, touch $TMPDIR/commit-guard/ok
                                     so the next git command passes the hook
```

## Pre-commit vs pre-push

| Check                       | pre-commit | pre-push |
|-----------------------------|------------|----------|
| File length                 | yes        | yes      |
| Comments / AI tells / Naming| yes        | yes      |
| Dead code                   | yes        | yes      |
| Secrets                     | yes        | yes      |
| Tests present               | yes        | yes      |
| Commit message format       | yes        | yes      |
| **Full build**              | no         | YES      |
| **Full test suite**         | no         | YES      |
| **Full lint pass**          | partial    | YES      |
| Breaking change scan        | yes        | yes      |

Pre-commit runs the cheap subset so the commit isn't slow; pre-push runs everything blocking.

## Violation report format

Always one consolidated table:

```
# commit-guard report — <ref or staged>

| # | Rule | File:line | Detail | Action |
|---|------|-----------|--------|--------|
| 1 | File length | path:N | 412 lines > 300 cap | Split into <suggested-files> |
| 2 | Comments policy | path:L | narrative comment | Remove |
| 3 | Dead code | path:L | unused import `X` | Remove; no callers found |
| 4 | Tests missing | path | function `doX` modified, no test changes | Add test for behavior change |
| 5 | Breaking change | path:L | `func Foo(a)` → `func Foo(a, b)` | Bump major; add CHANGELOG Changed entry; migration: <how> |

BLOCKED: <n> violations.
Suggested fix order: <1, 3, 2, 4, 5>.
```

### Ready-to-use fix prompt (MANDATORY on block)

When the report is BLOCKED, the skill ALWAYS emits a fenced prompt block the
user can paste back to drive the fix. Don't make them write it. The prompt:

- Names the specific files + line ranges from the violation table.
- Lists the rule violated for each item.
- Proposes a concrete refactor (split path, removal target, signature change,
  test stub, CHANGELOG entry) — not a vague "please fix".
- Preserves: existing exports, behavior, callers, public API; says so explicitly.
- Ends with "After fix, run <project build/test/lint> then re-run commit-guard."

Format:

```
Fix the following commit-guard violations in <repo path>:

<numbered list, one per violation, with file:line, rule, concrete action>

Preserve: <exports/behavior/contracts that must not change>.
After fix, run <build/test/lint command> then re-run commit-guard.
```

If multiple files violate the same rule (e.g. several files over the line
cap), group them under that rule with a shared remediation strategy.

If the only violations are authorize-able (tests missing on a portfolio,
pre-existing file-length, etc.), additionally surface the exact
authorization phrase the user can reply with, e.g.
`"authorize: ignore file-length for src/sections/Products.tsx this commit"`.

If everything passes:

```
commit-guard: clean. <n> files, <m> tests touched, <breaking|non-breaking>, scope `<scope>` valid for project.
Proceeding with commit.
```

## Exceptions

User must explicitly authorize per-change. Phrases that count as authorization:

- "skip commit-guard"
- "allow emoji here"
- "ignore file-length for this file"
- "no test for this change because <reason>"

Authorization is scoped to the current change only. Never persist a global override silently. If user wants a permanent project override, suggest adding it to project `CLAUDE.md`.

When user authorizes, the report still surfaces the exception in the final commit confirmation so it's visible in the conversation log.

## Language adapters

Each `references/languages/<lang>.md` defines:

- Build/lint/test commands
- Naming-convention authoritative source
- Dead-code detector
- Test-file-pattern (how to know if a test was added/modified)
- File-extension list
- Common bad patterns specific to language

If a language is encountered that has no adapter file:

1. Inspect the project for indicators (package files, config, conventions).
2. Look up the community-standard convention (cite the source: official style guide URL).
3. Propose the adapter content to the user.
4. Save to `references/languages/<lang>.md` after approval.

NEVER invent conventions. If unsure, ASK and cite sources.

## Test presence detection

Heuristic per language (in adapter file). Failure mode:

> Source file `foo.ts` was modified but no matching `foo.test.ts` / `foo.spec.ts` change in this commit. Why?

User must either: add test, or explicitly state the reason (refactor with no behavior change / typo fix / pure formatting). Reason is logged in commit message.

## Breaking-change detection

For each language adapter, define what a "public API surface" is. Compare staged diff against last tag (or `main`). Surface:

- Removed exported symbols
- Signature changes on exported symbols
- Type changes on exported fields
- Public route changes (HTTP/RPC)
- Database schema changes touching shared tables

Report with impact: best-effort scan for callers within the repo, link the file:line of each caller. Recommend the migration path.

## Output discipline

- Terse, technical.
- No emojis in output.
- No "great", "perfect", "I've successfully" — just status.
- One report, one decision gate, one summary line.
