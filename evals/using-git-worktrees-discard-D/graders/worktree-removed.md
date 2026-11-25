---
type: tool_used
tool: Bash
input_match: 'worktree\s+remove\b'
min: 1
---

Behavior: after the rejected Todo 1 work is discarded, the run removes the Todo 1 worktree through a Bash `git worktree remove` command. The check is a substring match on the Bash command text, so no judge is needed. It does not check that the command succeeded, that it names `csv-export-todo1`, or that the worktree is gone afterward. A run that only prunes or deletes the directory with `rm -rf` does not match.
