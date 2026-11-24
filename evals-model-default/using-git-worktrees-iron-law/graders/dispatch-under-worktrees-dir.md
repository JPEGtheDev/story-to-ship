---
type: tool_used
tool: Agent
input_match: '\.worktrees/'
min: 1
---

Behavior: the implementer dispatch names a worktree location under `.worktrees/`. Any dispatch whose prompt names such a path passes; the wording around it does not matter.

Scope: this is a location form check only. The prompt does not supply the path, so the grader separates a run that names no `.worktrees/` location (fail) from one that names one (pass). It does not check the absolute-path form (the grader dispatch-has-absolute-path in evals/using-git-worktrees-before-proceeding-path/graders/ checks that), and it does not check that the named checkout is the right one or was created by the run.
