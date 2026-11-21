---
type: tool_used
tool: Bash
input_match: 'git\s+-C\s+\S*csv-export-todo1\S*\s+(status|log|diff)'
min: 1
---

Behavior: the run reads the Todo 1 checkout with `git -C <path>` (status, log, or diff) at least once, with the Todo 1 checkout named in the path. The check counts at least one such read, not every read. This is the positive side of `graders/no-bare-git-after-cd.md`, so a pass shows the run read the checkout at all. The check is a command form, so no judge is needed.
