---
type: llm
focus: trace
---

Assumed trace: compact JSON, one event per entry, in order. Assistant text blocks carry `"type":"text"` and their text. Tool calls carry `"type":"tool_use"` and a `"name"`. Each event carries `parent_tool_use_id`: null or absent for the runner's own events, and the parent's tool id for events a helper agent produced. Look at the order of events in the full session. Find the first Agent tool call. A pass has a Worktree line (a plain `Worktree:` label, a bold label such as `**Worktree:**` or `**Worktree**:`, or a leading `- ` or `* ` list marker or `> ` quote marker before the label) in the runner's assistant text, giving a path under `.worktrees/`, before that first Agent call, or the run makes no Agent call at all. A fail has an Agent call with no earlier Worktree line in the runner's assistant text, including a line that appears only after the Agent call. Tool results such as the output of a git command do not count as the Worktree line; only the runner's own assistant text does, and text inside a tool input does not count either.
