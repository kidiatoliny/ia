---
name: copy-guard
description: Enforces user-facing copy standards across all projects. Auto-triggers when writing or editing visible strings (labels, headlines, taglines, button text, captions, error messages, marketing copy, READMEs). Use proactively whenever copy is created or modified. Also invokable directly via "/copy-guard audit" to scan a project for violations, or "/copy-guard check <text>" to validate a string. Reject emojis, slashes as separators, AI-tells, and unprofessional tone. Promote concise, context-aware, professional voice.
---

# copy-guard

Single source of truth for user-facing copy across every project the user works on. Apply BEFORE writing copy, and AUDIT existing copy on demand.

The user has repeated these rules many times. Honor them without being reminded.

## Hard rules

These are not preferences. They are rejections.

1. **No emojis.** Never in copy, never in commits, never in documentation, never in code comments, never in commit messages, never in PR titles or descriptions. The only exception is when the user explicitly asks for emojis ("make it playful with emojis", "add emoji icons").

2. **No slash separators in copy.** `X / Twitter` → `X`. `01 / 05` → `01 · 05`. `GitHub / Akira` → `GitHub · Akira`. `Sign in / Register` → `Sign in or register`. Code paths (`src/lib/foo.ts`), URLs, math, JSX className tokens, and date formats (`2026/05/16`) are fine — the ban is on slashes used as visible separators in prose, labels, counters, or taglines.

3. **No AI-tell phrases.** Banned: "Let me help you", "I'd be happy to", "Certainly!", "Of course!", "Feel free to", "Don't hesitate", "I hope this helps", "As an AI", "delve into", "leverage" (when "use" works), "robust solution", "seamlessly", "unlock the power of", "elevate your", "transform your", "in today's fast-paced world", "harness". If a phrase reads like LinkedIn-bot or ChatGPT default, kill it.

4. **No filler / hedging.** Banned in copy: "just", "really", "basically", "actually", "simply", "very", "quite", "perhaps", "essentially". Trim or rewrite.

5. **No exclamation marks** unless the brand voice is explicitly playful/casual and the user has signaled that. Default tone is calm and confident.

## Voice rules

- **Professional, context-aware.** Match the surface: a portfolio site reads differently from a dev tool's error message from a marketing landing page. Read what's around the copy before writing.
- **Concise.** Cut adjectives that aren't load-bearing. "Battle-tested production-grade scalable API inspector" → "API inspector".
- **Specific.** Numbers, names, concrete nouns. "Fast" is weak; "<10ms p99" is strong.
- **Active voice.** "We ship reliable software" not "Reliable software is shipped".
- **Confident without bragging.** "Built for teams that ship" not "The world's most powerful platform".

## Separators — the replacement table

When the urge to slash hits, pick from these:

| Want to express | Use | Don't |
|---|---|---|
| Two related labels | `Email · Newsletter` | `Email / Newsletter` |
| Counter | `01 · 05` or `01 of 05` or `01 — 05` | `01 / 05` |
| Either/or in copy | `Sign in or create an account` | `Sign in / Sign up` |
| Category split | `Frontend — React, Vue` | `Frontend / React, Vue` |
| Aliases | `X (formerly Twitter)` | `X / Twitter` |
| Location pair | `Cabo Verde — Luxembourg` | `Cabo Verde / Luxembourg` |

The middle dot `·` (U+00B7) is the default separator. Em-dash `—` works for stronger breaks.

## Workflow

### When writing new copy

1. Draft.
2. Self-audit against hard rules.
3. Check for AI-tells.
4. Verify tone matches surrounding context (look at the file or section).
5. Trim every adjective. If removal hurts meaning, keep it. Otherwise drop it.
6. Ship.

### When invoked as `/copy-guard audit`

Scan the current project for:
- Emojis in user-facing files (search `src/`, `app/`, `pages/`, `resources/`, `public/`, `README.md`).
- Slash separators in visible JSX text or string literals (heuristic: a `/` surrounded by spaces inside quotes or JSX text, ignoring code paths and URLs).
- Banned AI-tell phrases.
- Banned filler words.

Report findings as a list: `file:line — issue — suggested fix`. Don't auto-fix without asking unless the user already said "fix them all".

Search commands:
```bash
# emojis (broad emoji range)
grep -RPn '[\x{1F300}-\x{1FAFF}\x{2600}-\x{27BF}]' src/ app/ pages/ resources/ public/ 2>/dev/null

# slash as visible separator (rough)
grep -RnE '"[^"/<>]+ / [^"/<>]+"' src/ app/ resources/ 2>/dev/null
grep -RnE '> *[A-Za-z][^<]* / [^<]*<' src/ app/ resources/ 2>/dev/null

# AI-tells
grep -Rni -E "delve into|leverage|unlock the power|harness the|elevate your|transform your|seamlessly|robust solution|fast-paced world|happy to help|certainly!|of course!" src/ app/ resources/ README.md 2>/dev/null
```

### When invoked as `/copy-guard check <text>`

Run the text through every rule. Output PASS or list violations + rewrites.

## Domain-specific overrides

- **Code comments:** Same rules. No emojis, no slashes-as-separators, professional tone.
- **Commit messages:** No emojis. Conventional Commits format unless project says otherwise. Concise subject (≤72 chars).
- **PR descriptions:** Same. Lead with the why.
- **Error messages:** Plain, calm, actionable. "Connection refused. Check your network." not "Oops! Something went wrong! :("
- **Marketing copy on landing pages:** Slightly more aspirational allowed, but never crossing into AI-buzzword territory.

## When in doubt

Read the copy aloud. If it sounds like a human engineer wrote it for another human engineer, keep it. If it sounds like a SaaS template or an AI assistant, rewrite.
