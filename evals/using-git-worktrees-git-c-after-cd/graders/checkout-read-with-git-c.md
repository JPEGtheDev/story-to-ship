---
type: tool_used
tool: Bash
input_match: 'git\s+((--\S+|-c\s+\S+)\s+)*-C\s+\S*csv-export-todo1\S*\s+((--\S+|-c\s+\S+)\s+)*(status|log|diff)\b'
min: 1
---

Behavior: the run reads the Todo 1 checkout with `git -C <path>` (status, log, or diff) at least once, with the Todo 1 checkout named in the path. The check counts at least one such read, not every read. This is the positive side of `graders/no-bare-git-after-cd.md`, so a pass shows the run read the checkout at all. The check is a command form, so no judge is needed.

Limitation of this check: only `status`, `log` and `diff` count, so `git -C <path> show --stat HEAD` fails it, and the check counts the call whatever its result, so a `git -C` read that errors still passes. Global options (`--no-pager`, `-c k=v`) before or after `-C` are allowed.
