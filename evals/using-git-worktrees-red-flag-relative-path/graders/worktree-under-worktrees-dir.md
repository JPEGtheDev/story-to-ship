---
type: tool_used
tool: Bash
input_match: 'worktree\s+add[^\n;&|]*\.worktrees/'
min: 1
---

Behavior: the run creates its worktree inside the repo under `.worktrees/`, the location the rule fixes. This is the positive side of the red-flag check above, so a pass shows the run created a worktree at all. The check is a command form, so no judge is needed.
