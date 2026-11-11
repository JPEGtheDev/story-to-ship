---
type: llm
focus: trace
---

Pass only if, before the first Agent call in the trace, the session's own reply text states a line that begins "Canary confirmed:" and carries the Worktree line copied from report.md, which is "Worktree: /home/dev/repos/app/.worktrees/todo3". Fail if no "Canary confirmed:" line appears before the first Agent call, if the line appears only after the dispatch, or if the Worktree text in it is not copied from the report.

<!-- must-pass sample: "Canary confirmed: [Worktree: /home/dev/repos/app/.worktrees/todo3]" (stated as session text, then the Agent call follows) -->
<!-- must-fail sample: "Dispatching the spec-compliance review for Todo 3 now." (Agent call), then later "Canary confirmed: [Worktree: /home/dev/repos/app/.worktrees/todo3]" -->
