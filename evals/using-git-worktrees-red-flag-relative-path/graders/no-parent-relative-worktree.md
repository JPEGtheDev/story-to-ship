---
type: tool_used
tool: Bash
input_match: 'worktree\s+add(?:[^\n;&|\\]|\\"|\\\n|\\\\\\n)*(?:[\s"''/]|\\"|\\\n|\\\\\\n)\.\./'
min: 0
max: 0
---

Red flag: a `git worktree add` whose path argument starts with `../` puts the worktree outside the repo root. This grader fails the run when any Bash call runs `worktree add` with such an argument. It flags any `../` path component that follows a space, a quote, a slash or a line continuation in the arguments of a worktree add, in the raw command text and in its JSON-escaped form (an escaped quote or an escaped line continuation), not only a path that starts with `../`. The argument may come before or after flags, and may be quoted. The check is a command form, so no judge is needed.

Limitation of a zero-count check: a run that never creates a worktree also passes it. The paired grader `worktree-under-worktrees-dir` requires a worktree add under `.worktrees/`, which a pass must show.
