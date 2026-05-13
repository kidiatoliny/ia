---
name: instagram-carousel
description: Generate an 8-slide Instagram carousel (1080x1350) for the current project. Analyzes the codebase to detect project type, audience, and brand color, then writes HTML/CSS slides + a Chrome-headless render script. Use when the user asks for marketing slides, IG carousel, social post, "create a carousel", "promo slides", or similar.
---

# Instagram Carousel Generator

Generates an 8-slide Instagram carousel under `marketing/instagram/` for the project in CWD.

## Output layout

```
marketing/instagram/
  styles.css
  slide-1.html ... slide-8.html
  render.sh
  out/slide-1.png ... slide-8.png   (after render)
```

Also append `/marketing` to `.gitignore` if missing.

## Specs (non-negotiable)

- Canvas: **1080x1350** (4:5, IG-optimal).
- Language: **English** for all copy, comments, filenames.
- Style: dark background, radial gradient, brand color accent, subtle grid backdrop, **Inter** + **JetBrains Mono** via Google Fonts.
- No emojis anywhere.
- Renderer: `"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new --screenshot --window-size=1080,1350`.
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
- Instagram handle is not present anywhere (try `package.json` author, README, social links first).
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
8. **CTA** — `Follow @<handle> →` button + 3 platform/availability pills.

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
    --window-size=1080,1350 \
    --virtual-time-budget=4000 \
    "file://$DIR/slide-$i.html" >/dev/null 2>&1
  echo "✓ slide-$i.png"
done
ls -1 "$OUT"
```

`chmod +x render.sh` after writing.

## Step 7 — Execute

1. Create `marketing/instagram/` and `marketing/instagram/out/`.
2. Write `styles.css` (adapt brand color).
3. Write `slide-1.html` … `slide-8.html`. Show each in a Write tool call so the preview panel updates.
4. Write `render.sh`, `chmod +x`.
5. Append `/marketing` to `.gitignore` if not present.
6. Run `bash marketing/instagram/render.sh`.
7. List the generated PNGs.

## Rules

- Never use emojis (in copy or comments).
- Tone matches audience; do not write benefit-led fluff for a devtool or technical jargon for a consumer app.
- Copy is short and direct. Fragments OK. No filler ("simply", "just", "really").
- All filenames and copy in English regardless of conversation language.
- Don't invent stats. Pull versions from manifests; if a number is unknowable, pick a generic-but-true label (e.g. "Cross-platform" not "10× faster").
- Single CSS file. Pages compose existing classes; don't sprinkle bespoke styles per slide unless absolutely needed (`style="..."` for one-off layout overrides is fine).
