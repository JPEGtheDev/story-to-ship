---
type: tool_used
tool: Bash
input_match: '(?:"command"\s*:\s*"|&&|;|\|\|?|\\n)\s*git\s+(?:-C\s+(?:[^\s\\]|\\")+\s+)?worktree\s+remove\b(?:[^\n;&|\\"]|\\")*csv-export-todo1'
min: 1
---

Behavior: after the rejected Todo 1 work is discarded, the run removes the Todo 1 worktree through a Bash `git worktree remove` command. The check is a pattern match on the Bash command text, so no judge is needed. The git command must start a command (at the start of the command value, or after `&&`, `;`, a single `|`, `||` or a line break), and the same command must name the `csv-export-todo1` path. An `echo` or a comment that only contains the phrase no longer passes, and the name must sit in the command value, so a description that names it does not count. It does not check that the command succeeded or that the worktree is gone afterward. A run that only prunes or deletes the directory with `rm -rf` does not match.
