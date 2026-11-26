---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?worktree\s+add\b(?:[^"\\]|\\.)*?\s-b\s+(?!(?:\\"|["''])?agent/csv-export-todo1(?![\w./-]))[^\s"\;&|]+'
min: 1
---

Behavior: the run issues a Bash `git worktree add` whose `-b` argument is a branch name other than `agent/csv-export-todo1`, so after the branch is found in use the run picks a different name and adds the worktree. The pattern matches inside the Bash `command` value only, and the `-b` name must follow `worktree add` in that same command. It does not prove the add succeeded, that the new branch name is sensible, or that the checkout sits at `.worktrees/csv-export-todo1`. A run that adds with `-b agent/csv-export-todo1` (the failing command) does not match. A failing name written inside double or single quotes does not match either, and the tail check treats a letter, digit, dot, slash or hyphen after the name as part of the name. A run that adds without `-b`, for example by naming the existing branch, does not match either. The check is a command-form match, so no judge is needed.
