---
description: Add a feature to both onyx (Go) and onyx-rs (Rust), mirror across both repos, then offer release or PR.
---

Invoke the `onyx-feature` skill in **author mode only**.

Feature to implement: $ARGUMENTS

Constraints for this invocation:
- Skip mode detection. Go straight to author mode.
- Run Repo Discovery (SKILL.md § Repo Discovery) before any file change.
- Implement in both repos (Go first, then Rust mirror) unless user explicitly limits to one.
- End with the Post-Implementation Prompt (SKILL.md § Post-Implementation Prompt) — release, PR only, or nothing.
