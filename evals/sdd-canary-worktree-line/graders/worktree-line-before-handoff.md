---
type: regex
pattern: '(?:\\n|"|^)\s*Worktree:\s+[^\s"\\]*\.worktrees/'
match: contains
target: trace
---

Behavior: before the first handoff to another agent, the run states a line that starts with `Worktree:` and whose path sits under `.worktrees/`. The pattern looks for that line in the trace, where a newline shows as a literal backslash-n. It does not prove the line comes before the first Agent call; the process grader and the never grader judge order. A pass shows a `Worktree:` line with a `.worktrees/` path somewhere in the run. A fail shows no such line, for example a run that reports only a path under the main checkout or never states a Worktree line.
