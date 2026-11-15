---
type: llm
focus: last_message
---

Pass only if the final message states that a line beginning "Canary confirmed:" came before the first dispatch, or does not say it came after the first dispatch, and the Worktree text in that line is copied from report.md, which is "Worktree: /home/dev/repos/app/.worktrees/todo3". Fail if the final message says the "Canary confirmed:" line came after the first dispatch, or if the Worktree text in the line is not copied from the report.
