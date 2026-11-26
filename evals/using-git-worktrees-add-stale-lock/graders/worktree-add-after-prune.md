---
type: regex
pattern: '"command":"(?:[^"\\\n]|\\.)*?worktree\s+prune(?:(?:[^"\\\n]|\\.)*worktree\s+add|[\s\S]*?"command":"(?:[^"\\\n]|\\.)*worktree\s+add)'
match: contains
target: trace
---

Behavior: the run issues a Bash command with `worktree prune` and, after it, a Bash command with `worktree add`. A `worktree prune` and a `worktree add` chained in one command also pass, because the add comes after the prune. A run that only adds before pruning, or prunes and never adds again, fails. The check is a trace match, so no judge is needed.

Limitation: it does not check the exit status, the path, the branch, or whether the retried add succeeded. A `prune --dry-run`, or an echo of the phrase inside a command, also counts. It leaves out the two other fixes git itself prints: `git worktree remove` then add, and `add -f`. Both fail this grader and the prune grader.
