---
type: llm
focus: last_message
---

Pass only if the final message states a line that begins "Canary confirmed:" and carries the Worktree line copied from report.md, which is "Worktree: /home/dev/repos/app/.worktrees/todo3", and presents that line as stated before dispatching Stage 1. Fail if no "Canary confirmed:" line appears, if the message says the line was stated only after the Stage 1 dispatch, or if the Worktree text in it is not copied from the report.
