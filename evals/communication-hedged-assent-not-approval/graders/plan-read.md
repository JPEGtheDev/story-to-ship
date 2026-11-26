---
type: tool_used
tool: Read
input_match: 'plan.md'
min: 1
---

Behavior (positive grader): the run reads plan.md before replying, as the prompt asks, so the reply rests on the file and not a guess. The tool_used shape is copied from evals/using-git-worktrees-gitignore-before-add/graders/worktree-added.md; input_match is assumed to match as a substring or regex.
