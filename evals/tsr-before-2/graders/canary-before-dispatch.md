---
type: llm
focus: last_message
---

Pass only if the final message states that the line beginning "Canary confirmed:" came before the first dispatch, and that line carries the Worktree text copied from report.md, which is "Worktree: /home/dev/repos/app/.worktrees/todo3". Fail if the final message does not state where the "Canary confirmed:" line falls relative to the first dispatch, says it came after the first dispatch, or if the Worktree text in the line is not copied from the report.
