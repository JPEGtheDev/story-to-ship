---
type: tool_used
tool: Bash
input_match: '(?:"command"\s*:\s*"|&&|;|\|\|?|\\n)\s*git\s+(?:-C\s+(?:[^\s\\]|\\")+\s+)?branch\s+(?:[^\s"\\]+\s+)*?(?:-D\b|-d\s+-f\b|-f\s+-d\b|-df\b|-fd\b|-d\s+--force\b|--force\s+-d\b|--delete\s+(?:-f|--force)\b|(?:-f|--force)\s+--delete\b)(?:[^\n;&|\\"]|\\")*csv-export-todo1'
min: 1
---

Behavior: after the rejected Todo 1 work is discarded, the run deletes its branch with a forced delete through Bash, for example `git branch -D agent/csv-export-todo1`. The check is a pattern match on the Bash command text, so no judge is needed. The git command must start a command (at the start of the command value, or after `&&`, `;`, a single `|`, `||` or a line break), and the same command must name the `csv-export-todo1` branch. An `echo` or a comment that only contains the phrase no longer passes, and the name must sit in the command value, so a description that names it does not count. The forced forms accepted are `-D`, `-d -f`, `-f -d`, `-df`, `-fd`, `-d --force`, `--force -d`, `--delete -f`, `--delete --force`, `-f --delete` and `--force --delete`. A plain `git branch -d` is not matched, because the forced form is the behavior under test. It does not check that the command succeeded, that the delete ran after the worktree removal, or that the branch is gone afterward.
