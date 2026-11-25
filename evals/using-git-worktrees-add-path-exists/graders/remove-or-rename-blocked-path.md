---
type: tool_used
tool: Bash
input_match: '\b(rm|mv)\b[^\n;&|]*\.worktrees/csv-export-todo1'
min: 1
---

Behavior: when the target path .worktrees/csv-export-todo1 already exists as a plain directory, the run removes or renames that path with a Bash `rm` or `mv` command before it adds the worktree. The check is a command-form match, so no judge is needed. It also matches a Bash command that only mentions the phrase (an echo, a comment, or a dry run), and it does not check the order relative to the worktree add, the flags used, or whether the removed directory held anything the run should have kept. It does not check that the worktree was created afterward; the worktree-add grader covers that.
