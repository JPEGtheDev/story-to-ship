---
type: tool_used
tool: Bash
input_match: 'git\s+(-C\s+\S+\s+)?worktree\s+list[^\n;&|"\\]*\|\s*wc\b'
min: 0
max: 0
---

Red flag: `git worktree list | wc -l` used to decide whether the run is in a worktree. The rule says this does not tell which worktree the run is in. This grader fails the run when any Bash call pipes a `git worktree list` (plain or with flags such as `--porcelain`) into `wc`. The match stops at the end of the command, at a JSON-escaped newline or quote, so a `git worktree list` in one line of a command and a `wc` in a later line of it do not match. The check is a command form, so no judge is needed.

Limitation of a zero-count check: a run that never checks its location also passes it. A `git worktree list` without a pipe to `wc` is not failed here. A pipe through another command, such as `git worktree list | grep csv | wc -l`, is not caught. A `2>&1` redirect before the pipe (`git worktree list 2>&1 | wc -l`) is not matched, and neither is `--no-pager` or any other global option before `worktree list` (`git --no-pager worktree list | wc -l`). The paired grader `queries-show-toplevel` requires a root query, which a pass must show.
