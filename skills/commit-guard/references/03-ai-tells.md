# AI Tells — Blocked

Detect and block patterns characteristic of AI-generated text. Apply to code comments, user-facing copy (UI strings, marketing, READMEs, blog drafts), commit messages, and PR descriptions.

Override only when the user explicitly authorizes for the current change.

## Tier 1 — character-level (regex)

Block on detection:

- **Em-dash `—`** anywhere in prose (UI strings, READMEs, blog posts, marketing copy). Allowed inside code strings used as data, code blocks, and CLI option separators.
- **Emojis** in code, code comments, UI strings, commit messages, PR descriptions, and READMEs unless the user explicitly authorizes for that change.
- **Smart quotes** `“ ” ‘ ’` in code or commit messages. ASCII only.
- **Non-breaking spaces** in source files (U+00A0).
- **Zero-width characters** (U+200B U+200C U+200D U+FEFF).

## Tier 2 — phrase-level

Block these phrasings in prose:

### Opening clichés
- "In today's fast-paced world"
- "In the world of …"
- "With the advent of …"
- "Have you ever wondered …"
- "It's no secret that …"

### Filler transitions
- "Moreover,"
- "Furthermore,"
- "Additionally,"
- "In conclusion,"

### Filler verbs
- "Delve into"
- "Dive deep into"
- "Leverage" (when "use" works)
- "Utilize" (when "use" works)
- "Showcase" (when "show" works)
- "Embark on" (when "start" works)

### LLM apologies & disclaimers
- "I'm sorry, but as an AI …"
- "As a language model …"
- "I cannot …" / "I'm unable to …" patterns when generated as filler not as actual refusal.

### Listicle smell
- Sentences that end with exactly three abstract nouns ("speed, scale, and simplicity") that aren't real signals.
- "It's all about …" closings.

## Tier 3 — structural

Soft warn (allow with user confirmation):

- Three-bullet lists where each bullet is the same syntactic shape.
- Paragraphs that all start with a transition word.
- Excessive use of "comprehensive", "robust", "powerful", "seamless", "intuitive", "elegant" as descriptors with no concrete backing.

## Authorization

User authorizes per-change with a clear phrase: "allow emoji here", "em-dash is fine for this", "leave the phrasing as is". The exception applies to the current change only and is logged in the final commit confirmation.

## Detection scope

Pre-commit scan runs against staged diff for:

- All `.md`, `.mdx`, `.txt`, `.rst` files.
- All UI string files (`.tsx`/`.jsx` `Text`/`label` props, `messages.json`, locale files, Vue `<template>`, Svelte markup, HTML templates).
- Commit subject + body.
- Any user-facing copy detected in source (heuristic: string literals passed to known UI components or i18n functions).

Code identifiers and code logic are NOT scanned for tier-2 phrase-level rules (those target prose).
