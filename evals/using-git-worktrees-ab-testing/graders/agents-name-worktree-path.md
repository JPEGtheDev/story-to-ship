---
type: tool_used
tool: Agent
input_match: '\.worktrees/'
min: 2
---

Behavior: the run makes at least two Agent calls whose prompts name a `.worktrees/` path, so each candidate approach is sent into its own worktree. The check is a substring match on each dispatch input, so the wording around the path does not matter. It does not prove the two paths differ, so one path reused for both calls also passes. The check is a substring match on the dispatch input, so no judge is needed.
