---
type: tool_used
tool: Bash
input_match: 'branch\s+(-D\b|--delete\s+--force\b|--force\s+--delete\b)'
min: 1
---

Behavior: after the rejected Todo 1 work is discarded, the run deletes its branch with a forced delete through Bash: `git branch -D agent/csv-export-todo1` or the long form `git branch --delete --force` (either flag order). The check is a substring match on the Bash command text, so no judge is needed. It does not check that the command succeeded, that the branch name is the rejected one, or that the delete ran after the worktree removal. A plain `git branch -d` is not matched, because the forced form is the behavior under test. It does not check that the branch is gone afterward.
