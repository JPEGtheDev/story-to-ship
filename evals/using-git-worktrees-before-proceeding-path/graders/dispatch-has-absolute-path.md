---
type: tool_used
tool: Agent
input_match: '(?:(?<![\w.])|(?<=\\n)|(?<=\\t))/[^\s"`]*\.worktrees/'
min: 1
---

Behavior: the implementer dispatch prompt names the worktree by its absolute path (a path that starts at the root and ends in `.worktrees/...`). A relative `.worktrees/` mention alone does not match, because the rule asks for the absolute path so the subagent does not resolve it against its own working directory. The lookbehind keeps `repo/.worktrees/` (a path with a leading segment) from matching as absolute. The check is a path form, so no judge is needed.
