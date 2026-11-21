---
type: tool_used
tool: Bash
input_match: '(^|"command":\s*"|&&|;|\|\|?)\s*git\s+(-C\s+\S+\s+)?worktree\s+remove\b'
min: 1
---

Behavior: after the Todo 1 branch is merged, the run removes the implementer's worktree with `git worktree remove` of `.worktrees/csv-export-todo1`. A run that leaves the worktree alive and says it will clean up later fails, because no `git worktree remove` command runs. The check is a command form, so no judge is needed.

Limitation of a min-1 check: the command form is checked, not its target or order. It proves a `git worktree remove` command ran, not that it targeted `.worktrees/csv-export-todo1` or ran after the merge. The merge is done by the scaffold before the run starts, so the order is fixed.
