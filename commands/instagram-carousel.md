---
name: instagram-carousel
description: Generate an 8-slide Instagram carousel (1080x1080) for the current project. Analyzes the codebase to detect project type, audience, and brand color, then writes HTML/CSS slides + a Chrome-headless render script. Use when the user asks for marketing slides, IG carousel, social post, "create a carousel", "promo slides", or similar.
---

# Instagram Carousel Generator

Generates an 8-slide Instagram carousel for the project in CWD. Output lives on the user's Desktop, OUTSIDE the project repo — never inside it.

## Output layout

Resolve `~/Desktop/marketing.<slug>/` where `<slug>` is the project name (kebab/lowercase). Examples: `~/Desktop/marketing.spectra/`, `~/Desktop/marketing.orbit/`, `~/Desktop/marketing.unified-dev/`.

```
~/Desktop/marketing.<slug>/
  styles.css
  slide-1.html ... slide-8.html
  render.sh
  out/slide-1.png ... slide-8.png   (after render)
```

Slug rules:
- Lowercase, kebab-case.
- Source from `package.json` `name`, `Cargo.toml` `name`, `pyproject.toml` `project.name`, etc. Fall back to README title or repo folder name.
- Strip org prefixes (`@akira/spectra` → `spectra`).

Caption is NOT a file. Printed in final chat response as copy-paste-ready block.

`.gitignore`: not needed — output is outside repo. Do NOT touch project's `.gitignore`.

## Specs (non-negotiable)

- Canvas: **1080x1080** (1:1 square).
- Language: **English** for all copy, comments, filenames.
- Style: dark background, radial gradient, brand color accent, subtle grid backdrop, **Inter** + **JetBrains Mono** via Google Fonts.
- No emojis anywhere.
- Renderer: `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --screenshot --window-size=1080,1080`.
- Copy is short, sentence fragments OK.

## Step 1 — Analyze the project

Before writing copy, detect what the project IS. Look at:

- `README*`, `docs/` for name, tagline, value prop.
- Manifests: `package.json`, `pyproject.toml`, `requirements.txt`, `Cargo.toml`, `go.mod`, `composer.json`, `Gemfile`, `pubspec.yaml`, `*.csproj`, `build.gradle`, `Podfile`.
- Source tree (`src/`, `app/`, `lib/`, `cmd/`, `internal/`) to infer framework.
- Theme/CSS files for brand color hints (`--primary`, `--accent`, `theme.json`, tailwind config).
- `wails.json` / `electron-builder.json` / `tauri.conf.json` for desktop apps.

Infer:
- **Name + tagline** from README/manifest `productName`/`description`.
- **Audience**: devs, designers, end users, businesses.
- **Brand color**: parse CSS custom properties or tailwind theme. If absent, pick one fitting the domain (devtool → violet/cyan, finance → green, AI → magenta, design → orange, etc.).
- **Tone**: technical for devs, benefit-led for consumers, outcome-led for B2B.

## Step 2 — Ask only if ambiguous

Default to making the reasonable call and continuing. Only stop to ask when:
- Audience is genuinely unclear from the codebase.
- Instagram handle: do NOT invent or guess from project/org name (no `@akira_foundation`, no `@<project>` etc). Search only in: `package.json` author/social fields, README links, and any social config files. If not found there, ALWAYS default to **`@kidiatoliny_`** — never invent.
- User explicitly invoked the skill with "ask me first".

If the user has said "work without stopping", do not ask — pick defaults and continue.

## Step 3 — Narrative (8 slides)

Adapt the examples to the project's actual domain. Keep the structure.

1. **Hook** — user pain. Short line with one **strikethrough** word (the incumbent / wrong way).
2. **Problem** — concrete example matching the domain: terminal mock for CLI/devtool, UI mock for app, chart for data tool, before-state for design tool.
3. **Reveal** — big product name (`.bigword`) + tagline (`.subtitle`) + 3–4 pills.
4. **How it works** — 3 numbered steps.
5. **Primary feature** — 3-column grid with monogram icons (`{ }`, `~`, `✓` style — not emojis).
6. **Secondary feature** — domain-matched visual: terminal for CLI, screenshot/UI mock for app, diagram for infra, chart for data.
7. **Stack / specs** — 4 stats. Pick what impresses the target audience: tech versions, bundle size, perf numbers, scale, pricing, integrations.
8. **CTA** — `Follow @<handle>` button (handle resolution rules: see Step 2; default `@kidiatoliny_` — never guess from project name) + 3 platform/availability pills.

## Step 4 — Reusable CSS components

Build `styles.css` once with these classes (do not invent new ones per slide):

`.slide`, `.brand` + `.brand-dot` + `.brand-name`, `.eyebrow`, `.title` (with `.accent` and `.strike` modifiers), `.subtitle`, `.bigword`, `.terminal` (`.t-head` + `.t-body` with `.tprompt` / `.tdim` / `.terr` / `.tok` / `.twarn` / `.tmuted`), `.pill` + `.pills`, `.feature` + `.feature-grid` + `.feature-icon` + `.feature-title` + `.feature-desc`, `.step` + `.steps` + `.step-num` + `.step-title` + `.step-desc`, `.stat` + `.stats` + `.stat-label` + `.stat-value` (`.unit`), `.cta-btn`, `.platform` + `.platforms`, `.footer` + `.pager` + `.swipe`.

Reference template: see `templates/styles.css` in this skill folder — copy and recolor by swapping `--accent` / `--accent-2` / `--accent-dim` to match the project's brand.

## Step 5 — HTML structure (every slide)

```html
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>PROJECT · N</title>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="styles.css">
</head>
<body>
<section class="slide">
  <div class="top">
    <div class="brand"><span class="brand-dot"></span><span class="brand-name">NAME</span></div>
    <div class="brand" style="color:var(--dim)">0N / 08</div>
  </div>
  <div class="content"> ... </div>
  <div class="footer">
    <div class="pager">NAME / 0N</div>
    <div class="swipe">swipe →</div>
  </div>
</section>
</body>
</html>
```

Slide 8 footer uses the website/handle instead of `swipe →`.

## Step 6 — render.sh

```bash
#!/usr/bin/env bash
set -euo pipefail
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$DIR/out"
mkdir -p "$OUT"
for i in 1 2 3 4 5 6 7 8; do
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars \
    --default-background-color=00000000 \
    --screenshot="$OUT/slide-$i.png" \
    --window-size=1080,1080 \
    --virtual-time-budget=4000 \
    "file://$DIR/slide-$i.html" >/dev/null 2>&1
  echo "✓ slide-$i.png"
done
ls -1 "$OUT"
```

`chmod +x render.sh` after writing.

## Step 7 — Caption (printed in chat, NOT a file)

At the end of the run, print a copy-paste-ready Instagram caption inside a fenced code block in the chat reply. Do NOT write it to disk.

Goal: short, assertive, scroll-stopping. **Not** a recap of the slides — the slides already say what the product does. The caption adds reframing, contrast, or a punchline a reader can't get from the visuals alone.

Format:

```
<line 1: punchy contrast or reframe. ~6–10 words. Names the incumbent or the wrong way, names the product. NOT a question, NOT a slide-1 echo.>

<2–3 short sentences expanding the angle. Each sentence ≤ 14 words. New information, not slide bullets reworded.>

<one-line value verb-chain or status update — e.g. "Run. Mock. Snapshot. Ship." or "Beta's open. No waitlist.">

Follow @<handle>

#tag1 #tag2 #tag3 #tag4 #tag5
```

Rules:
- **Native English.** No literal translations, no awkward phrasing ("read on contact", "framework-aware as a service"). Read it out loud — if a fluent dev wouldn't say it, rewrite.
- **No em-dash slashes** (` — `) anywhere in the caption. Use periods. Em-dashes look fine on slides; in IG caption they break the rhythm and look AI-generated.
- **No filler.** No "really", "simply", "just", "the future of", "say goodbye to", "introducing".
- **No slide-copy reuse.** If a sentence already appears on a slide, rewrite or cut it.
- **No emojis.**
- **Contractions OK** ("doesn't", "it's", "beta's") — they read native.
- 5–8 hashtags max, domain-relevant (devtools, opensource, github, etc).
- Handle matches slide 8 (default `@kidiatoliny_`, never guess).
- Tone matches slide audience: technical for devtools, benefit-led for consumer, outcome-led for B2B.
- Total length under ~60 words excluding hashtags. Aim for shorter.

## Step 8 — Execute

Let `DEST="$HOME/Desktop/marketing.<slug>"`.

1. Create `$DEST/` and `$DEST/out/`.
2. Write `$DEST/styles.css` (adapt brand color).
3. Write `$DEST/slide-1.html` … `slide-8.html`. Show each in a Write tool call so the preview panel updates.
4. Write `$DEST/render.sh`, `chmod +x`.
5. Run `bash "$DEST/render.sh"`.
6. List generated PNGs.
7. Print caption (Step 7) in a fenced code block — never skip.

Never write under the project's working tree. Never modify project's `.gitignore`.

## Rules

- Never use emojis (in copy or comments).
- Tone matches audience; do not write benefit-led fluff for a devtool or technical jargon for a consumer app.
- Copy is short and direct. Fragments OK. No filler ("simply", "just", "really").
- All filenames and copy in English regardless of conversation language.
- Don't invent stats. Pull versions from manifests; if a number is unknowable, pick a generic-but-true label (e.g. "Cross-platform" not "10× faster").
- Single CSS file. Pages compose existing classes; don't sprinkle bespoke styles per slide unless absolutely needed (`style="..."` for one-off layout overrides is fine).
