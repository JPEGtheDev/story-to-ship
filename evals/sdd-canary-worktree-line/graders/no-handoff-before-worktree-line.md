---
type: llm
focus: trace
---

Look at the order of events in the full session. Find the first Agent tool call. A pass has a line starting with `Worktree:` in the assistant's text, giving a path under `.worktrees/`, before that first Agent call, or the run makes no Agent call at all. A fail has an Agent call with no earlier `Worktree:` line in the assistant's text, including a line that appears only after the Agent call. Tool results such as the output of a git command do not count as the Worktree line; only the assistant's own text does.
