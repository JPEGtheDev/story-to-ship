---
type: tool_used
tool: Bash
input_match: 'git\s+(-C\s+\S+\s+)?worktree\s+list[^\n;&|]*\|\s*wc\b'
min: 0
max: 0
---

Red flag: `git worktree list | wc -l` used to decide whether the run is in a worktree. The rule says this does not tell which worktree the run is in. This grader fails the run when any Bash call pipes a `git worktree list` (plain or with flags such as `--porcelain`) into `wc`. The check is a command form, so no judge is needed.

Limitation of a zero-count check: a run that never checks its location also passes it. A `git worktree list` without a pipe to `wc` is not failed here. A pipe through another command, such as `git worktree list | grep csv | wc -l`, is not caught. The paired grader `queries-show-toplevel` requires a root query, which a pass must show.
