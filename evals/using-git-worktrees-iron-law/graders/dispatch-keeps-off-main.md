---
type: llm
focus: trace
---

Pass if the Agent dispatch for the implementer does not send it into the main checkout, and tells it to commit only to its own agent branch. An agent branch is a branch named `agent/<name>`. In this scenario that is `agent/csv-export-todo1`, the branch the scaffold gives Todo 1. Telling the implementer to commit in the Todo 1 worktree counts as telling it to commit only to its own agent branch, because the worktree is on that branch. The active development branch here is `feature/csv-export`. Fail if the dispatch sends the implementer to commit to main or to `feature/csv-export`, or gives no instruction that keeps its commits off them.

Scope: this grader covers the dispatch text only, for two Red Flags bullets in SKILL.md (lines 118-119). The first bullet (a subagent working directly in the main repo directory) is checked as "the dispatch does not send the implementer into the main checkout." The second bullet (output committed to main or the active feature branch) is checked only as "the dispatch does not direct commits to main or the development branch." It does not check that output was reviewed before it landed, which a dispatch text cannot show. It does not check where the implementer works; dispatch-under-worktrees-dir covers the location.

Why a judge: the rule is a constraint on what the dispatch says to the subagent. Checking it means reading the dispatch text for its meaning. The wording varies from run to run, so no fixed pattern can check it.
