---
type: tool_used
tool: Bash
input_match: 'git\s+-C\s+\S+\s+status|git\s+-C\s+\S+\s+log|git\s+-C\s+\S+\s+diff'
min: 1
---

Behavior: the run reads the Todo 1 checkout with `git -C <path>` (status, log, or diff), so every git read targets that checkout explicitly. This is the positive side of `graders/no-bare-git-after-cd.md`, so a pass shows the run read the checkout at all. The check is a command form, so no judge is needed.
