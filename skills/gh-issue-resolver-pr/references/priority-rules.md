# Priority Rules

Use this as tie-breaker guidance after label-based scoring.

## Severity first
- Production incidents, security flaws, data loss: immediate.
- Broken critical business flows: next.
- Non-critical functional bugs: then.
- Enhancements/docs/chore: last.

## Impact
Prioritize the issue affecting more users, money flow, compliance, or support load.

## Confidence
If two issues have similar impact, prioritize the issue with clearer reproduction and lower implementation risk to accelerate delivery.

## Age and momentum
When urgency is equal, oldest issue first.

## Dependencies
If issue B blocks issue A, do B first.
