# Priority Model (`P0` to `P3`)

## Decision Order
Evaluate in this order and stop at the first matching level.

1. `P0` Critical
- Security vulnerability with plausible exploitation.
- Data loss/corruption risk.
- Production outage or hard blocker in critical flows.

2. `P1` High
- Severe regressions in core flows (auth, payments, checkout, legal/compliance).
- High user impact with no acceptable workaround.
- Repeated failures in important async or integration paths.

3. `P2` Medium
- Important but non-critical reliability/usability defects.
- Technical debt causing frequent developer friction or moderate risk.
- Partial workaround exists.

4. `P3` Low
- Minor UX issues, polish items, low-risk refactors, non-urgent docs/tasks.

## Tie-Breakers
When in doubt between two priorities:
- Choose higher priority if blast radius is broad.
- Choose higher priority if detectability is low and failure is silent.
- Choose lower priority if impact is local and workaround is trivial.

## Suggested Labels
- Priority label: `priority:P0`, `priority:P1`, `priority:P2`, `priority:P3`
- Type label: `type:bug`, `type:task`, `type:refactor`, `type:security`
