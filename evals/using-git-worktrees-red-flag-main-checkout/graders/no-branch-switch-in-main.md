---
type: tool_used
tool: Bash
input_match: 'git\s+(-C\s+\S+\s+)?(checkout|switch)\b(?=[^\n;&|]*\s(-[bBcC]|--detach|--orphan)(\s|$)|\s+(-\S*\s+)*(?!main(\s|$|[;&|]))[^-\s])|gh\s+pr\s+checkout\b'
min: 0
max: 0
---

Red flag: `git checkout -b`, `git switch` to a branch, `git checkout <branch or commit>` or `gh pr checkout` in the main checkout. This grader fails the run when any Bash call runs one of them. Returning to `main` (`git checkout main` or `git switch main`, with optional flags such as `-q`) is allowed by the rule, so the pattern excludes it. A detached checkout (`--detach`) is flagged even when it names `main`, and `main~1` or any other commit is flagged. A `-C <path>` prefix does not hide a hit.

Design choice: the pattern flags these commands in any directory, not only the main checkout. The rule's fix is to create the branch with `worktree add -b`, and a run that switches branches anywhere has not followed that path. The check is a command form, so no judge is needed.

Limitation of a zero-count check: a run that never reaches the branch step also passes it. The paired grader `branch-made-with-worktree` requires a worktree add, which a pass must show.
