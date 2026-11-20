---
type: llm
focus: trace
---

Pass if, in the trace, the checkout is created first, then the root of that checkout is queried, and the query's result is compared with the worktree path (the result must be the worktree, not the main repo root), and only after that the implementer is dispatched with the Agent tool. Fail if the Agent dispatch comes before the root query, if the query is never compared with the worktree path, or if the result is the main repo root and the run goes ahead anyway.

Why a judge: the rule depends on order (check before dispatch) and on a comparison the run makes in its reasoning. Neither shows up as a tool count, so the trace must be read.
