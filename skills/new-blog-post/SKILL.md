---
name: new-blog-post
description: Co-author a new blog post for kid.akira-io.com (the Kidiatoliny portfolio at /Users/kid/Akira/me). Use when the user says "write a blog post", "new post", "new blog post", "/new-post", "publish a post", "draft a post", "write about X for the blog", or otherwise signals they want to author long-form writing. This skill REFUSES to ghostwrite — it interviews the user first, refuses to invent stories, and produces drafts that read like a senior engineer wrote them, not an LLM. Locks the portfolio repo as the only output target (prompts for the path if it's not at the default location). Handles project context (Spectra, Unified Dev, NoxDireit, Akira Packages, Akira Debugger, or personal), language selection (EN default, PT optional), MDX frontmatter, file placement, voice + copy-guard audit, and a paired Instagram carousel (3-8 square slides, generated under the portfolio so it reuses the site palette, rendered to PNG into ~/Desktop/blogs/<slug>/). Output is always saved into src/content/writing/<slug>.mdx of the portfolio repo, ready to commit.
---

# new-blog-post

Authoring assistant for the Akira / Kidiatoliny writing collection. The mission is to ship **human-sounding, opinion-driven, evidence-rich** posts that earn the reader's attention. Most blogs are skimmed. The ones that land have a strong claim, real stories, specific numbers, and a clean point of view.

**Hard rule:** This skill never invents facts, never invents user quotes or anecdotes, never makes up benchmarks. If the post needs a number, a story, or a concrete example and the user has not given it, **ask**.

The user has explicitly asked for posts that read like a human wrote them. Treat any LLM-flavored phrasing as a regression.

## Phase 0 — Locate the portfolio repo (mandatory)

All output goes inside the portfolio repo. No exceptions. Before anything else:

1. Check if `/Users/kid/Akira/me` exists and contains `src/content/writing/`. If yes → that is the target. Proceed.
2. If the path does not exist or is not the portfolio, ask the user:

   > Where is the portfolio repo located? It must contain `src/content/writing/` and `src/styles/global.css`.

3. Validate the answer:
   ```bash
   test -d "$REPO/src/content/writing" && test -f "$REPO/src/styles/global.css"
   ```
   If validation fails, ask again. Do not guess. Do not write anything yet.
4. Lock the path into a variable for the rest of the run. From this point, "the repo" always means this path.

Posts are written into `$REPO/src/content/writing/<slug>.mdx`. IG slide HTML is generated inside `$REPO/tmp/ig/<slug>/` (gitignored) so it can pull the portfolio's CSS variables and fonts. PNG renders are output to `~/Desktop/blogs/<slug>/`.

## Phase 1 — Brief intake

Before writing anything, run a short interview. Use `AskUserQuestion` for each block when possible. Do NOT proceed to draft until every required answer is in.

### 1.1 Subject (required) — pick from menu

Use `AskUserQuestion` with these options:

```
question: "What is this post about?"
header: "Subject"
options:
  - "Spectra"
  - "Unified Dev"
  - "NoxDireit"
  - "Akira Debugger"
  - "Akira Packages"
  - "Personal / engineering practice / career"
```

After they pick, ask one short follow-up: **One-sentence summary in your own words.** Capture verbatim. The working title comes from this sentence, not an LLM-generated one.

### 1.2 Angle (required) — pick or write your own

Never ask "what is the angle?" open-ended. **Generate 3 to 5 concrete candidate claims based on the subject the user gave in 1.1, plus an "Other" option.** Present them as a numbered list. The user picks one or writes a custom claim.

Build the candidate list according to which product or theme is in play. Examples — adapt the actual claims to fit the user's specific subject sentence:

**If subject is Spectra:**
1. "Comecei Spectra porque Postman é wrong shape pra Laravel devs."
2. "Spectra existe porque toda equipa Laravel reinventa Postman collections manualmente."
3. "O primeiro feature que funcionou foi auto-discovery. Tudo dependeu disso."
4. "Generic API clients lose. Opinionated ones win."
5. Other: __________

**If subject is Unified Dev:**
1. "Issue trackers and CI dashboards live apart by accident, not by design."
2. "I built Unified Dev because context-switching between GitHub, Linear, and Vercel costs more than any of them charge."
3. "Time tracking that lives with the branch beats time tracking that lives in a separate tool."
4. Other: __________

**If subject is NoxDireit:**
1. "Cape Verde's legal market does not have a legal-tech stack. I am building one."
2. "Generic LLMs cannot do CV jurisprudence. The corpus is the moat."
3. "Lawyers do not want chatbots. They want drafting tools."
4. Other: __________

**If subject is Akira Debugger:**
1. "Laravel debugging is stuck in 2014. PHP 8.4 should change that."
2. "Strict types are not a constraint. They are a debugger."
3. Other: __________

**If subject is Akira Packages:**
1. "Twenty-five packages, one rule: each one solves a real problem I had."
2. "Open source compounds slower than people think and faster than people expect."
3. Other: __________

**If subject is personal / engineering / career:**
1. "From an island in the Atlantic to a five-product company. The geography is not the constraint."
2. "Most architecture decisions are memory-tax decisions, not technical ones."
3. "I shipped X. Y broke. Z is the rule I keep."
4. Other: __________

If the user picks "Other", they must write a one-sentence claim. If their custom claim is a description ("explains how X works") not a point of view, push back with concrete alternatives, do not accept it. Stay in this loop until the angle is a defensible claim.

### 1.3 Evidence the user has (required) — present a numbered menu

Never ask "what evidence do you have?" as an open prose question. **Present a numbered list of evidence categories tailored to the subject, ask the user to pick at least 2, and require concrete detail for each.** Reject categorical answers ("code samples", "numbers") — they must give the actual thing.

Standard menu (adapt to the subject):

```
1. Inciting moment — the exact moment you decided to build / write this.
   Bug? Frustration? Customer ask? Approximate date.
2. First line of code — file path or repo URL. What was it? I will read it.
3. First feature shipped — which one, how many days after starting.
4. First user — real or anonymous? When? What did they say?
5. Big rewrite — did you start from scratch ever? Why?
6. Specific code sample — file path, function name, or PR link.
7. Numbers — downloads, stars, latency, bundle size, line count, dates.
8. Quote from a real conversation — Slack, email, GitHub issue. Verbatim.
9. Comparison artifact — before/after screenshot, diff, two configs side by side.
10. External link to cite — prior post, RFC, library docs.
11. Other — describe.
```

Push-back rules:

- If the user says "code samples" without specifying which, stop and ask which file.
- If the user names a number without giving the value, stop and ask for the value.
- If the user gives fewer than 2 evidence items, stop and tell them: "Two pieces minimum. Otherwise the post will read like a generic AI essay. What is the smallest concrete thing you can attach to this argument?"
- If the user has nothing concrete, propose to drop the topic and pick one where they have evidence.

Capture each evidence item verbatim. The draft will quote or reference these exact items. No paraphrasing of unverified claims.

### 1.4 Audience (required) — pick from menu

Use `AskUserQuestion`:

```
question: "Who is this post for?"
header: "Audience"
options:
  - "Senior backend engineers (Laravel-shaped)"
  - "Indie hackers / founders"
  - "Cape Verdean / lusophone tech audience"
  - "General product engineers"
  - "Hiring managers / future collaborators"
```

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

### 1.7 Tags (required) — multi-select menu

Use `AskUserQuestion` with `multiSelect: true`:

```
question: "Which tags fit this post? Pick up to four."
header: "Tags"
multiSelect: true
options:
  - "dx"
  - "strategy"
  - "systems"
  - "engineering"
  - "cabo-verde"
  - "infra"
  - "ai"
  - "laravel"
  - "tauri"
  - "career"
  - "product"
  - "open-source"
```

If the user wants a tag outside this taxonomy, they must justify it as a new category. Default to existing tags. Cap at 4.

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
date: <full ISO datetime at the moment of writing, e.g. 2026-05-17T18:00:00Z — distinct timestamps avoid same-day sort ties>
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

## Phase 7 — Instagram carousel (mandatory)

Every post ships with an Instagram carousel — between 3 and 8 square slides — plus a caption. The carousel must:

- Reuse the portfolio's CSS variables, fonts, and visual language. Never invent palette.
- Generate slide HTML inside the portfolio repo at `$REPO/tmp/ig/<slug>/` so it has access to `$REPO/src/styles/global.css` via relative `@import` or copied variables.
- Output rendered PNGs to `~/Desktop/blogs/<slug>/slide-01.png` … `slide-NN.png`.
- Cycle accent colors across slides — same colors used by the portfolio, never colors outside that set.
- Surface only **key triggers** — claims, numbers, quotes — that pull the reader to the full article. The carousel is not a summary of the post. It is the bait.

### 7.1 Folders

```
$REPO/tmp/ig/<slug>/        # gitignored, HTML source for each slide
  slide-01.html
  slide-02.html
  ...
~/Desktop/blogs/<slug>/     # output PNGs + caption
  slide-01.png
  slide-02.png
  ...
  caption.txt
```

Create both folders before writing files. Confirm `tmp/` is gitignored in the portfolio repo (most are; if not, add `tmp/` to `.gitignore`).

### 7.2 Palette — locked to portfolio

The portfolio palette is defined in `$REPO/src/styles/global.css` under the `@theme` block. Read it from the file before each run — do not hardcode in the skill — and use **only** these tokens:

| Token            | Use                                  |
|------------------|--------------------------------------|
| `--color-void`   | background base                      |
| `--color-deep`   | secondary background, slide variant  |
| `--color-ink`    | tertiary background                  |
| `--color-fog`    | subtle surfaces, borders             |
| `--color-bone`   | primary text                         |
| `--color-violet` | accent A                             |
| `--color-neon`   | accent B (default for personal)      |
| `--color-glow`   | accent C                             |
| `--color-cyan`   | accent D (Spectra)                   |
| `--color-amber`  | accent E (NoxDireit)                 |
| `--color-magenta`| accent F (Akira Packages)            |
| `--color-jade`   | accent G (Akira Debugger)            |

Accent rotation for the carousel — pick a primary based on the post's `accent` frontmatter (or product), then cycle through complementary tokens for subsequent slides:

- Personal posts → `[neon, cyan, amber, jade, magenta, glow, violet]`
- Spectra posts → `[cyan, neon, glow, violet]`
- Unified Dev posts → `[neon, glow, violet, cyan]`
- NoxDireit posts → `[amber, neon, glow, magenta]`
- Akira Debugger posts → `[jade, neon, cyan, glow]`
- Akira Packages posts → `[magenta, neon, glow, violet]`

Cycle and reuse if there are more slides than colors in the list. Do not introduce any new color.

### 7.3 Slide types and order

Plan the slides BEFORE writing HTML. Use this order:

1. **Hook slide** — the post's strongest one-liner. Big type. Title-level. Same accent as the OG card.
2. **Stake slide** — what's at risk if you ignore this. One short sentence.
3. **Claim slides (1–3)** — each carries one specific trigger: a number, a contrarian one-liner, a named example. One idea per slide.
4. **Counter slide** (optional) — the obvious counter, addressed in a single line.
5. **CTA slide** — title + "Full post at kid.akira-io.com/writing/<slug>" + swipe-handoff or "Read →" chip. Always last.

Length:
- Short post → 3 slides (hook, claim, CTA).
- Medium post → 5 slides (hook, stake, 2 claims, CTA).
- Long post → 7–8 slides (hook, stake, 3–4 claims, counter, CTA).

Each slide's text must be repeatable out loud. If a slide takes more than 6 seconds to read, cut.

### 7.4 Slide template

Slides share a base layout. Use this skeleton — content is the only thing that changes per slide. Save as `$REPO/tmp/ig/<slug>/slide-NN.html`.

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Geist:wght@400;500;700&family=Geist+Mono:wght@300;400;500&display=swap" rel="stylesheet">
  <style>
    /* mirrors $REPO/src/styles/global.css @theme palette */
    :root {
      --color-void: #04020a;
      --color-deep: #0a0518;
      --color-ink: #120a26;
      --color-fog: #1d1438;
      --color-violet: #7c3aed;
      --color-neon: #b388ff;
      --color-glow: #d8b4fe;
      --color-bone: #f5f0ff;
      --color-amber: #fbbf24;
      --color-cyan: #7dd3fc;
      --color-magenta: #f472b6;
      --color-jade: #34d399;

      --bg: var(--color-void);
      --fg: var(--color-bone);
      --mute: color-mix(in oklab, var(--color-bone) 55%, transparent);
      --hairline: color-mix(in oklab, var(--color-bone) 12%, transparent);
      --accent: ACCENT_TOKEN;
    }

    * { box-sizing: border-box; margin: 0; }
    html, body { width: 1080px; height: 1080px; overflow: hidden; }
    body {
      background:
        radial-gradient(ellipse at 85% 15%, color-mix(in oklab, var(--accent) 22%, transparent), transparent 58%),
        radial-gradient(ellipse at 10% 95%, color-mix(in oklab, var(--accent) 10%, transparent), transparent 55%),
        var(--bg);
      color: var(--fg);
      font-family: "Geist", system-ui, sans-serif;
      padding: 88px;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      letter-spacing: -0.01em;
    }

    /* ── header */
    .topbar { display: flex; align-items: center; justify-content: space-between; font-family: "Geist Mono", monospace; font-size: 18px; color: var(--mute); }
    .brand { display: flex; align-items: center; gap: 14px; }
    .brand-dot { width: 28px; height: 28px; border-radius: 7px; background: linear-gradient(135deg, var(--color-violet), var(--accent)); }
    .counter { font-variant-numeric: tabular-nums; }

    /* ── center content variants */
    .stage { display: flex; flex-direction: column; justify-content: center; gap: 24px; flex: 1; }

    .display-xl {
      font-size: 108px;
      font-weight: 500;
      line-height: 0.98;
      letter-spacing: -0.05em;
      max-width: 920px;
    }
    .display-lg {
      font-size: 84px;
      font-weight: 500;
      line-height: 1.02;
      letter-spacing: -0.045em;
      max-width: 920px;
    }
    .display-md {
      font-size: 62px;
      font-weight: 500;
      line-height: 1.1;
      letter-spacing: -0.035em;
      max-width: 880px;
    }
    .body-lg {
      font-size: 30px;
      line-height: 1.45;
      color: var(--mute);
      max-width: 820px;
    }
    .number {
      font-size: 220px;
      font-weight: 600;
      line-height: 1;
      letter-spacing: -0.06em;
      color: var(--accent);
      font-variant-numeric: tabular-nums;
    }
    .accent { color: var(--accent); }
    .kicker {
      font-family: "Geist Mono", monospace;
      font-size: 16px;
      letter-spacing: 0.18em;
      text-transform: uppercase;
      color: var(--accent);
    }
    .quote::before {
      content: "“";
      color: var(--accent);
      font-size: 1.2em;
      line-height: 0;
      margin-right: 0.1em;
    }

    /* ── footer */
    .footer { display: flex; align-items: flex-end; justify-content: space-between; }
    .dots { display: flex; gap: 8px; }
    .dot {
      width: 10px; height: 10px; border-radius: 999px;
      background: color-mix(in oklab, var(--color-bone) 18%, transparent);
    }
    .dot.on { background: var(--accent); }
    .cta {
      font-family: "Geist Mono", monospace;
      font-size: 16px;
      letter-spacing: 0.14em;
      text-transform: uppercase;
      color: var(--accent);
      border: 1px solid color-mix(in oklab, var(--accent) 40%, transparent);
      padding: 12px 20px;
      border-radius: 999px;
    }
    .url {
      font-family: "Geist Mono", monospace;
      font-size: 18px;
      color: var(--mute);
    }
    .url .path { color: var(--fg); }
  </style>
</head>
<body>
  <header class="topbar">
    <span class="brand">
      <span class="brand-dot"></span>
      <span>kid.akira-io.com</span>
    </span>
    <span class="counter">NN · TOTAL</span>
  </header>

  <section class="stage">
    <!-- SLIDE_BODY -->
  </section>

  <footer class="footer">
    <span class="dots">
      <!-- DOTS -->
    </span>
    <span class="cta">FOOTER_CTA</span>
  </footer>
</body>
</html>
```

Substitutions:

- `ACCENT_TOKEN` → one of `var(--color-neon)`, `var(--color-cyan)`, etc. — picked from the rotation in 7.2.
- `NN · TOTAL` → e.g. `02 · 05`. Use middle dot, never `/`.
- `DOTS` → one `<span class="dot on"></span>` for current slide, the rest `<span class="dot"></span>`. Total dots = total slides.
- `FOOTER_CTA`:
  - Slides 1 through N-1 → `SWIPE →` (no period).
  - Last slide → `READ → KID.AKIRA-IO.COM/WRITING/<SLUG>` truncated if needed, OR a short `READ →` chip alongside a `.url` block in the body.

`SLIDE_BODY` examples — pick the variant that matches the slide type:

```html
<!-- hook: -->
<h1 class="display-xl">HOOK <span class="accent">PUNCH.</span></h1>

<!-- stake: -->
<span class="kicker">STAKE</span>
<p class="display-lg">SHORT_STATEMENT.</p>

<!-- claim with number: -->
<span class="kicker">CLAIM_LABEL</span>
<p class="number">32K+</p>
<p class="body-lg">SUPPORTING_LINE.</p>

<!-- claim as one-liner: -->
<p class="display-md accent">ONE_LINE_CLAIM.</p>

<!-- quote: -->
<p class="display-md quote">QUOTE_FROM_POST.</p>

<!-- counter: -->
<span class="kicker">COUNTER</span>
<p class="display-md">OBVIOUS_COUNTER_LINE.</p>

<!-- CTA last slide: -->
<span class="kicker">FULL POST</span>
<p class="display-lg">READ_LINE.</p>
<p class="url">kid.akira-io.com<span class="path">/writing/<SLUG></span></p>
```

Choose accents per slide from the rotation list, never outside the palette. Re-cycle if you run out.

### 7.5 Render to PNG via Chrome headless

Detect the available Chrome binary in order and use the first one that exists:

```
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
"/Applications/Chromium.app/Contents/MacOS/Chromium"
"/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"
```

Render each slide individually:

```bash
"$CHROME" \
  --headless=new \
  --disable-gpu \
  --hide-scrollbars \
  --no-sandbox \
  --window-size=1080,1080 \
  --default-background-color=00000000 \
  --screenshot="$HOME/Desktop/blogs/<slug>/slide-NN.png" \
  "file://$REPO/tmp/ig/<slug>/slide-NN.html"
```

Loop NN from 01 to TOTAL. After every render verify the file is `PNG image data, 1080 x 1080`. If any slide fails, re-render after fixing the template.

If no Chrome binary is found, fall back: instruct the user to open each `tmp/ig/<slug>/slide-NN.html`, screenshot at 1080×1080, save as `slide-NN.png`.

### 7.6 Caption

Write `caption.txt` in `~/Desktop/blogs/<slug>/`. Format:

```
<HOOK_LINE>

<SHORT_PARAGRAPH_FROM_POST — 2 to 3 lines, lifted or rewritten, no spoilers>

Swipe → for the key points.
Full post → https://kid.akira-io.com/writing/<slug>

—
<HASHTAG_LINE>
```

Caption rules:
- **Hook** is one line. Strong claim, not a question. Mirror the post's angle, do not summarise the whole post.
- Caption body 2–3 short lines. Aim for under 220 characters total before the URLs — keeps the IG preview clean.
- **No emoji.** Same skin as the site.
- **Hashtags** 6–10, lowercase, single spaces on the last line. Pick from these pools, do not invent:
  - product: `#spectra #unifieddev #noxdireit #akiradebugger #akirapackages`
  - topic: `#devtools #laravel #typescript #react #rust #tauri #engineering #dx #productengineering`
  - personal: `#capeverde #luxembourg #indiehacker #foundermode`
- Always include the post URL line.
- If language is PT, write the caption in PT.

### 7.7 Share copy per platform (mandatory)

Write `share.md` to `~/Desktop/blogs/<slug>/`. This file holds ready-to-paste share copy with a fresh hook per platform — never reuse the summary verbatim. The summary is for the OG card. The share copy is the trigger.

Structure:

```markdown
# <slug> — share copy

URL: https://kid.akira-io.com/writing/<slug>
OG image: /og/<slug>.png (auto-generated at build)
IG carousel cover: ~/Desktop/blogs/<slug>/slide-01.png

---

## X / Twitter (≤ 280 chars)
<HOOK_X>

https://kid.akira-io.com/writing/<slug>

---

## Bluesky (≤ 300 chars)
<HOOK_BLUESKY>

https://kid.akira-io.com/writing/<slug>

---

## LinkedIn (1-2 short paragraphs, professional)
<HOOK_LINKEDIN_PARAGRAPH>

<OPTIONAL_FOLLOWUP_PARAGRAPH>

https://kid.akira-io.com/writing/<slug>

---

## Threads / Mastodon (≤ 500 chars)
<HOOK_THREADS>

https://kid.akira-io.com/writing/<slug>

---

## IG caption (uses ~/Desktop/blogs/<slug>/caption.txt)
See caption.txt for IG-specific copy with hashtags.

---

## Hashtag pool used
<pool list>
```

Rules for the hooks:

- Each platform gets a **different** opening line. Never copy-paste the summary.
- **X / Twitter:** punchy contrarian one-liner. Cut every word that does not earn its slot.
- **Bluesky:** slightly more space, more personality. Can be a two-beat hook ("I shipped X. It broke. Here is why I did Y.").
- **LinkedIn:** lead with the lesson, not the story. One paragraph of setup, one of takeaway. Avoid corporate voice — keep it human, but with more context than X.
- **Threads / Mastodon:** match Bluesky energy.
- Always end with the post URL on its own line.
- No emoji. No banned phrases. Run the same voice rules from Phase 3.
- Include the OG image / IG cover references at the top so the user knows what preview will render.

If a deploy has not happened yet, add a note at the top:

> Note: previews will only render after deploying the post. Until then, social share boxes will show URL-only.

### 7.8 Report

Print to the user:

```
IG carousel (N slides):
  HTML source: $REPO/tmp/ig/<slug>/
  PNG output:  ~/Desktop/blogs/<slug>/slide-01.png … slide-NN.png   (1080 × 1080 each)
  Caption:     ~/Desktop/blogs/<slug>/caption.txt
  Share copy:  ~/Desktop/blogs/<slug>/share.md  (X · Bluesky · LinkedIn · Threads)
  OG image:    /og/<slug>.png (built into dist/, live after deploy)
  URL:         https://kid.akira-io.com/writing/<slug>
  Accent palette used: <list>
```

If you fell back to manual screenshot, say so explicitly.

## Phase 8 — Translation (only if user opted into bilingual)

For each additional language:

1. Re-run the intake briefly (audience may differ for the lusophone version — Cape Verde-specific framing, real examples in PT).
2. Translate the structure, not the words. Rewrite the opener for the target audience.
3. Apply the same voice rules in the target language.
4. Save as `src/content/writing/<slug>-<lang>.mdx`.
5. Update both files' frontmatter `translations:` to cross-link.
6. Re-run copy-guard against the translated draft.
7. Re-run Phase 7 for the PT version — fresh slides under `$REPO/tmp/ig/<slug>-pt/`, PNGs into `~/Desktop/blogs/<slug>-pt/slide-NN.png`, caption in PT pointing to `/writing/<slug>-pt`. Same accent rotation, translated copy.

Do not run any translation through a generic LLM-translate. The user has explicitly asked for human-feel posts. AI translation is a regression.

## What this skill never does

- Never writes a post without intake.
- Never invents anecdotes, customer stories, or benchmarks.
- Never generates illustrative or decorative imagery from a prompt. The only image it produces is the deterministic IG template render (Phase 7). For inline diagrams or screenshots, it describes what is needed and asks the user to provide them.
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
