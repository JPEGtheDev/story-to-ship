---
type: tool_used
tool: Bash
input_match: 'worktree\s+add\b'
min: 1
---

Behavior: the feature branch is created with a worktree add, which puts it in its own checkout and keeps the main checkout on `main`. This is the positive side of the switch check above, so a pass shows the run took the approved path. The check is a command form, so no judge is needed.
