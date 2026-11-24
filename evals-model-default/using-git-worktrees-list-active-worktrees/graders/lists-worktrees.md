---
type: tool_used
tool: Bash
input_match: 'worktree list'
min: 1
---

Behavior: the run lists the active worktrees with a Bash `git worktree list` command, plain or with `-C <path>`. The grader checks only that a list command ran; it does not check the order against the first Agent call, which the paired list-before-dispatch grader checks, and it does not check the output the run read. The check is a command-form match, so no judge is needed.
