---
name: new-blog-post
description: Co-author a new blog post for kid.akira-io.com / akira-io.com properties. Use when the user says "write a blog post", "new post", "new blog post", "/new-post", "publish a post", "draft a post", "write about X for the blog", or otherwise signals they want to author long-form writing. This skill REFUSES to ghostwrite — it interviews the user first, refuses to invent stories, and produces drafts that read like a senior engineer wrote them, not an LLM. Handles project context (Spectra, Unified Dev, NoxDireit, Akira Packages, Akira Debugger, or personal), language selection (EN default, PT optional), MDX frontmatter, file placement, thumbnail planning, and final voice + copy-guard audit. Output is always saved into src/content/writing/<slug>.mdx of the target repo, ready to commit.
---

# new-blog-post

Authoring assistant for the Akira / Kidiatoliny writing collection. The mission is to ship **human-sounding, opinion-driven, evidence-rich** posts that earn the reader's attention. Most blogs are skimmed. The ones that land have a strong claim, real stories, specific numbers, and a clean point of view.

**Hard rule:** This skill never invents facts, never invents user quotes or anecdotes, never makes up benchmarks. If the post needs a number, a story, or a concrete example and the user has not given it, **ask**.

The user has explicitly asked for posts that read like a human wrote them. Treat any LLM-flavored phrasing as a regression.

## Phase 1 — Brief intake

Before writing anything, run a short interview. Use `AskUserQuestion` for each block when possible. Do NOT proceed to draft until every required answer is in.

### 1.1 Subject (required)

Ask: **What is this post about?**

Sub-questions:
- Is it about a specific Akira product (Spectra, Unified Dev, NoxDireit, Akira Debugger, Akira Packages) or about Kidiatoliny / engineering practice / career?
- One-sentence summary in the user's own words.

Capture the answer verbatim. The post's working title should come from this sentence, not a generic LLM title.

### 1.2 Angle (required)

Ask: **What is the argument? What changes for the reader after they read this?**

Push back if the answer is "it explains how X works". That is a manual page, not a blog post. A post has a **point of view**: a claim the user is making that someone else might disagree with.

Examples of accepted angles:
- "Postman is generic. Spectra is opinionated. Generic loses."
- "Most architecture decisions are memory-tax decisions, not technical ones."
- "Cape Verde does not have a developer-tools market yet. Here is how I am building it anyway."

Examples to reject and rephrase:
- "Spectra has cool features" → ask: which feature, and why does it matter that it exists at all?
- "How I built X" → ask: what is the lesson someone takes away that they could not get from your README?

### 1.3 Evidence the user has (required)

Ask the user to list, before drafting:
- Specific numbers, benchmarks, timing data they want included.
- Real anecdotes — a moment, a customer, a debugging session — that supports the angle.
- Code samples from the actual repo, or paths to grab them from.
- Links to prior posts, PRs, issues, or external articles to cite.

If the user has no concrete evidence, the post will be generic. Stop and tell them: "This post needs at least one specific example before it is worth writing. What is the smallest concrete thing you can attach to this argument?"

### 1.4 Audience (required)

Ask: **Who is this for?**

Options to offer:
- Senior backend engineers (Laravel-shaped).
- Indie hackers / founders.
- Cape Verdean / lusophone tech audience.
- General product engineers.
- Hiring managers / future collaborators.

The audience determines tone, depth of jargon, and what to skip.

### 1.5 Language (required)

Use `AskUserQuestion`:

```
question: "Which language(s) should this post ship in?"
header: "Language"
options:
  - "English only" — default for technical posts
  - "English + Portuguese" — when audience includes lusophone tech
  - "Portuguese only" — Cape Verde-specific or PT-first
```

If user picks bilingual, plan for two MDX files with matching `translations:` cross-references in frontmatter. By default ship EN-only and tell the user PT can be added later without breaking links.

### 1.6 Length (required)

Use `AskUserQuestion`:

```
question: "How long should this post run?"
header: "Length"
options:
  - "Short (400–700 words)" — single argument, single example
  - "Medium (800–1500 words)" — argument + 2-3 supporting moves
  - "Long (1500–3000 words)" — deep-dive, multiple sections, code-heavy
```

Resist any urge to default to long. Most strong posts are medium.

### 1.7 Tags (required)

Ask: **What tags?** Constrain to the existing taxonomy where possible: `dx`, `strategy`, `systems`, `engineering`, `cabo-verde`, `infra`, `ai`, `laravel`, `tauri`, `career`, `product`, `open-source`. Allow new tags only if the post genuinely opens a new category.

### 1.8 Hero / thumbnail

OG images are generated automatically by `astro-og-canvas` at build (title + summary on a void gradient). Inline images are optional.

Ask: **Are there any inline images, diagrams, or screenshots to include?**

If yes, the user must provide file paths or upload them. Do not generate or invent images. If a diagram would help, **describe what the diagram should show** in plain words and ask the user to produce it (Figma, Excalidraw, hand-sketch, or screenshot from the product).

If the user wants a custom hero image for the post itself (not the OG card), accept a `hero:` path in frontmatter pointing to `/public/...`.

## Phase 2 — Outline

Before writing prose, produce an outline as a numbered list and show it to the user. Format:

```
1. Hook — <one sentence describing the opener>
2. The claim — <the angle, sharpened>
3. Section A — <subhead>
   - point
   - evidence: <which specific anecdote/number from intake>
4. Section B — ...
5. Cost / counter-argument — <what the most skeptical reader would say, addressed>
6. The shipping line — <what the reader does or thinks differently tomorrow>
```

Get explicit user approval ("ship the outline" or edits) before writing prose. Outlines that do not have evidence assigned to each section are not approved — go back to intake.

## Phase 3 — Draft

Write the post into `src/content/writing/<slug>.mdx` of the target repo (default `/Users/kid/Akira/me`). Slug is `kebab-case-from-title`.

### Frontmatter

```mdx
---
title: "<the actual headline, sentence case>"
summary: "<one sentence, 110–160 chars, that earns the click>"
date: <ISO date today>
tags: [<from intake>]
draft: false
lang: en   # or pt
accent: "<hex; pick from the product accent if product-specific, else #b388ff>"
translations:
  pt: <slug-pt>   # only if a PT version exists or is planned
---
```

Accent palette to use when product-specific:
- Spectra → `#7dd3fc`
- Unified Dev → `#c4b5fd`
- NoxDireit → `#fbbf24`
- Akira Debugger → `#34d399`
- Akira Packages → `#f472b6`
- Personal / general → `#b388ff`

### Voice rules — non-negotiable

These are the rules that separate human posts from LLM posts. Apply them as you write, and audit again at the end.

1. **Open on a concrete moment, a strong claim, or a contrarian one-liner.** Not a definition. Not a "have you ever wondered". Not "in today's fast-paced world".
2. **First-person where it is honest.** "I shipped this. I was wrong. I learned." Plural "we" only when there is a real team.
3. **Short sentences mixed with longer ones.** Vary cadence. Read the draft aloud — if every paragraph has the same shape, rewrite.
4. **Specific over generic.** Numbers, names, file paths, commit hashes, dates. "8 minutes" beats "fast". "PHPStan level 9" beats "type-safe".
5. **Active voice, present tense by default.**
6. **State opinions as claims, not hedged opinions.** "This is the wrong default" not "this might arguably be considered the wrong default".
7. **Show the cost.** Every architectural choice has a cost. State it. Acknowledging cost is the cheapest credibility signal there is.
8. **Address the most skeptical reader.** One paragraph that says "yes, this looks like X, here's why it isn't" or "the obvious counter is Y, here's the trade".
9. **One idea per paragraph.** When a paragraph gets to 4+ sentences and shifts topic, split it.
10. **End on a line the reader can repeat.** Not a summary. A claim.

### Banned phrases (absolute)

If any of these appear in the draft, rewrite until they don't:

- "delve into", "delves", "let's delve"
- "leverage" (use _use_)
- "harness the power of", "unlock the power of"
- "elevate your", "transform your", "supercharge your"
- "robust solution", "seamless experience", "cutting-edge"
- "in today's fast-paced world", "in the modern era", "in this digital age"
- "it is worth noting", "it is important to note", "it is essential to"
- "let's explore", "let's dive into", "let's take a closer look"
- "as we have seen", "as previously mentioned", "as discussed earlier"
- "the world of …" ("the world of APIs", "the world of developer tools")
- "with the advent of"
- Sentences that begin with "Moreover," "Furthermore," "Additionally," — restructure
- Em-dash + abstract phrase pattern: "X — a paradigm shift in Y" → rewrite
- Triple-list patterns where every list is exactly three abstract nouns: "speed, scale, and simplicity"

### Banned filler words (in copy)

`just`, `really`, `basically`, `actually`, `simply`, `very`, `quite`, `perhaps`, `essentially`, `clearly`, `obviously`. Trim or rewrite.

### Structure templates by length

**Short (400–700w):** one hook, one claim, one anecdote, one counter, one closer. No subheadings unless needed.

**Medium (800–1500w):** hook → claim → 2-3 short sections with `## ` subheads → counter section → closer.

**Long (1500–3000w):** hook → claim → 4-6 sections, can include code blocks, diagrams, callouts → cost section → closer. Use `### ` sub-subheads sparingly.

### MDX components available

If the user wants embedded interactive bits, the project ships:
- Code blocks (Shiki, dark theme) via fenced ```lang.
- Blockquotes for short claims.
- Standard markdown. No custom MDX components yet — propose adding `<Callout>`, `<Note>`, `<Compare>` only if the post genuinely needs them, and tell the user to confirm.

## Phase 4 — Voice review (delegated)

After the draft is written, invoke the `design:ux-copy` skill (Skill tool, `design:ux-copy`) to review the post's micro-copy: headline, summary, subheads, call-out lines, CTA at the end. Apply its feedback.

Then invoke `copy-guard` (Skill tool, `copy-guard`) with the action `check` against the full draft. Resolve every flagged item — do not negotiate down on hard rules.

## Phase 5 — Final read-through

Self-audit checklist before declaring the post ready:

- [ ] Opens on a moment or claim, not a definition.
- [ ] Headline does not contain a colon followed by a buzzword phrase ("X: The Future of Y").
- [ ] Every section has at least one specific (number, name, code, path).
- [ ] No banned phrases, no banned filler.
- [ ] One counter-argument addressed.
- [ ] Closer is a line the user could put on a t-shirt.
- [ ] Word count matches the agreed length within ±15%.
- [ ] Frontmatter complete, including `summary` that earns the click.
- [ ] `summary` does not start with the title rephrased.
- [ ] If product-specific, `accent` matches the product color.
- [ ] If bilingual, `translations` field cross-references the PT slug and vice versa.
- [ ] Slug is short, kebab-case, no stop words ("the", "a", "on"). E.g. `cognitive-load-as-strategy`, not `the-cognitive-load-of-product-decisions`.

## Phase 6 — Save and report

1. Write the file to `src/content/writing/<slug>.mdx`.
2. Verify build:
   ```bash
   cd /Users/kid/Akira/me && bun run build
   ```
3. Report to the user with:
   - File path.
   - Word count.
   - Reading time estimate (words / 220, rounded up).
   - Live URL preview (`/writing/<slug>`).
   - Any open `TODO:` markers left in the draft.
4. Do NOT commit. The user decides when to commit and push.

## Phase 7 — Translation (only if user opted into bilingual)

For each additional language:

1. Re-run the intake briefly (audience may differ for the lusophone version — Cape Verde-specific framing, real examples in PT).
2. Translate the structure, not the words. Rewrite the opener for the target audience.
3. Apply the same voice rules in the target language.
4. Save as `src/content/writing/<slug>-<lang>.mdx`.
5. Update both files' frontmatter `translations:` to cross-link.
6. Re-run copy-guard against the translated draft.

Do not run any translation through a generic LLM-translate. The user has explicitly asked for human-feel posts. AI translation is a regression.

## What this skill never does

- Never writes a post without intake.
- Never invents anecdotes, customer stories, or benchmarks.
- Never generates images. It can describe what an image would help with and ask the user to provide one.
- Never commits to git.
- Never ships a draft that contains banned phrases.
- Never picks a clickbait headline. Headlines must be the claim of the post in plain language.
- Never auto-translates. PT posts are written, not converted.

## Quick-start examples

If the user says: "write a post about why I dropped Lenis"
→ Ask: angle (engineering decision? warning to others?), audience (frontend devs?), evidence (the actual symptom, the actual fix, the actual diff), length, language. Then outline.

If the user says: "blog post about Spectra route discovery"
→ Probable angle: opinionated over generic. Probable evidence: how `route:list` parsing works, before/after of a real Laravel project. Ask which one to use.

If the user says: "personal post about Cape Verde dev scene"
→ Probable angle: market is not built yet, here is the move. Probable evidence: real conversations, real numbers (devs, salaries, infra cost), real names of orgs. Ask the user to confirm what is publishable.
