---
type: llm
focus: trace
---

Pass if, in the trace, the run queries the root of the checkout it was given with `git rev-parse --show-toplevel` before the Agent dispatch, the query's result is compared with the worktree path (the result must be the worktree, not the main repo root), and only after that the implementer is dispatched with the Agent tool. Other forms of the query, such as `git rev-parse --git-dir` or `pwd`, do not pass. Fail if the Agent dispatch comes before the `git rev-parse --show-toplevel` query, if that query is never compared with the worktree path, or if the result is the main repo root and the run goes ahead anyway.

Why a judge: the rule depends on order (check before dispatch) and on a comparison the run makes in its reasoning. Neither shows up as a tool count, so the trace must be read.
