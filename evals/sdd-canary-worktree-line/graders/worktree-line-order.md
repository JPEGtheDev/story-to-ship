---
type: llm
focus: trace
---

Assume the trace is compact JSON with each assistant text block and each tool call in order. Find the first Agent tool call. A pass has a Worktree line in the assistant's own text, followed by a path under `.worktrees/`, appearing before that first Agent call. A Worktree line takes the same forms the sibling graders accept: a plain label (`Worktree:`), a bold label (`**Worktree:**` or `**Worktree**:`), a backtick-wrapped path, and a leading list marker (`- ` or `* `) or quote marker (`> `) before the label. A fail has the first Agent call coming before any such line, or no such line appearing in the assistant's text at all. Tool results (for example git output or a file read) do not count as the Worktree line; only the assistant's own text does. A run that makes no Agent call passes only if the Worktree line still appears in the assistant's text; with no such line it fails.
