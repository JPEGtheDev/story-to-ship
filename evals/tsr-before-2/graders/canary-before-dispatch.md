---
type: llm
focus: trace
---

Pass only if the session text before the first Agent call in the trace states a line that begins "Canary confirmed:" and carries the Worktree line copied from report.md, which is "Worktree: /home/dev/repos/app/.worktrees/todo3". Fail if no "Canary confirmed:" line appears before the first Agent call, if the first Agent call comes before that line, or if the Worktree text in the line is not copied from the report.
