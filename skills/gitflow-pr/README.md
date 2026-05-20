# gitflow-pr

Create PR with gitflow base inference.

Hooks already handle commit/push validation (gitflow-guard, commit-guard).
This skill only creates the PR with smart base branch detection.

## Usage

```
/gitflow-pr [--base branch]
```

## Examples

```bash
# Default: infer base (milestone/vX.Y.Z or main)
/gitflow-pr

# Override base branch
/gitflow-pr --base main
```

## Flow

1. **After** you've committed and pushed (hooks validate)
2. **Infers** base branch: looks for milestone/vX.Y.Z, falls back to main
3. **Creates PR** with `gh pr create`

## Requirements

- Git repository on feature branch
- Branch already pushed to origin
- `gh` CLI configured
- Existing gitflow setup (hooks in ~/.claude/hooks/)

## Exit codes

- `0` — success
- `1` — error (not in repo, or `gh pr create` failed)
