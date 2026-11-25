---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?=(?:[^"\\]|\\.)*?\.worktrees/)(?:[^"\\]|\\.)*?(?:branch\s+--show-current|rev-parse\s+--abbrev-ref)'
min: 1
---

Behavior: per the Create step of the using-git-worktrees skill, after a worktree is created the run queries that worktree's current branch, so it can confirm the branch is not the active development branch. The check passes when one Bash command names a `.worktrees/` path and also runs `branch --show-current` or `rev-parse --abbrev-ref`, for example `git -C .worktrees/<name> branch --show-current`. The path and the query must sit in the same command string; the pattern does not check order, does not check that the query came after `worktree add`, and does not check that the returned branch was compared with feature/csv-export. A query run against the main checkout with no `.worktrees/` path in the command fails this grader. The check is a command-form match on the serialized tool input, so no judge is needed.
