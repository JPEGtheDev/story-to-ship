---
type: tool_used
tool: Bash
input_match: 'git\s+(-C\s+\S+\s+)?worktree\s+(remove|prune)\b'
min: 1
---

Behavior: after the Todo 1 branch is merged, the run removes the implementer's worktree (`git worktree remove` of `.worktrees/csv-export-todo1`, or `git worktree prune` after the checkout is gone) in its own Bash call. A run that leaves the worktree alive and says it will clean up later fails, because no removal or prune command runs. The check is a command form, so no judge is needed.

Limitation of a min-1 check: it proves a removal or prune command ran, not that it targeted `.worktrees/csv-export-todo1` or ran after the merge. The merge is done by the scaffold before the run starts, so the order is fixed.
