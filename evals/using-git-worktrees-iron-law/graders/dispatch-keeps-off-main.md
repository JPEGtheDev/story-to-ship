---
type: llm
focus: trace
---

Pass if the Agent dispatch tells the implementer to work only in its own worktree and to commit only to its own agent branch, and does not direct it to commit to main or to the active development branch. Fail if the dispatch sends the implementer to commit to main or to the active development branch, or gives no instruction that keeps it off them.

Why a judge: the rule is a constraint on what the dispatch says to the subagent. Checking it means reading the dispatch text for its meaning. The wording varies from run to run, so no fixed pattern can check it.
