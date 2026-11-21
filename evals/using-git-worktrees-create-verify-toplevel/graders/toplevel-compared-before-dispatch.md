---
type: llm
focus: trace
---

Pass if, in the trace, the run queries the root of the checkout it was given with `git rev-parse --show-toplevel` (with or without `-C <path>`) before the Agent dispatch, the query's result is compared with the worktree path (the comparison counts when the run's reply or a Bash call states that the query's result equals the worktree path before the Agent call; the result must be the worktree, not the main repo root), and only after that the implementer is dispatched with the Agent tool. Other forms of the query, such as `git rev-parse --git-dir` or `pwd`, do not pass. Fail if the Agent dispatch comes before the `git rev-parse --show-toplevel` query, if the run dispatches with no toplevel query, or with a query whose result is not compared with the worktree path, or if the result is the main repo root and the run goes ahead anyway.

Why a judge: the rule depends on order (check before dispatch) and on a comparison the run states in its reply or a Bash call. Neither shows up as a tool count, so the trace must be read.

Limitation: the judge reads a trace whose middle may be elided, so a pass depends on what the judge can see. This grader is not a measurement of order by itself, and the case is reported as no signal.
