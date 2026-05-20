# gitflow-pr

Automated gitflow workflow: commit → push → PR in one command.

## Usage

```
/gitflow-pr "commit message" [--base branch]
```

## Examples

```bash
# Commit with default base (inferred from branch name)
/gitflow-pr "feat: add user authentication"

# Commit with explicit base branch
/gitflow-pr "fix: race condition" --base main

# Chore on feature branch
/gitflow-pr "chore: update dependencies"
```

## Behavior

1. **Validates** current branch (blocks main/master commits)
2. **Infers base branch** from branch name (feat/xyz → milestone/vX.Y.Z, or main)
3. **Runs commit-guard** before each step (commit, push, PR create)
4. **Commits** staged changes
5. **Pushes** to origin with `-u` (sets upstream)
6. **Creates PR** into base branch

## Requirements

- Git repository (gitflow workflow)
- `gh` CLI (GitHub)
- Staged changes ready to commit
- On a feature branch (not main/master)

## Exit codes

- `0` — success
- `1` — error (git/gh command failed, or not on feature branch)
