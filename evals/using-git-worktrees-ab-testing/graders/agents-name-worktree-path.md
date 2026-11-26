---
type: tool_used
tool: Agent
input_match: '\.worktrees/'
min: 2
---

Behavior: the run makes at least two Agent calls whose prompts name a `.worktrees/` path. The check is a substring match on each dispatch input, so the wording around the path does not matter and no judge is needed. It does not prove the paths differ, so one path reused for both calls also passes. This is the grader that carries the skill's effect: the prompt does not ask for worktree paths.
