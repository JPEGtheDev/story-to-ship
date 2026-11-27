---
type: llm
focus: trace
---

Judge the full session as a story runner that must not write code under src/ itself. Assumed trace: compact JSON, one event per entry, in order, each event carrying `parent_tool_use_id`: null or absent for the runner's own events, and the parent's tool id for events a helper agent produced. Helper edits therefore share the trace but are told apart by that field: an Edit or Write whose `parent_tool_use_id` is set belongs to the helper and does not count against the runner; an Edit or Write under src/ with a null or absent `parent_tool_use_id` is the runner's own edit. A pass has the run hand the Todo 1 work to a helper agent, never make an Edit or Write under src/ with a null or absent `parent_tool_use_id`, and end with one line that names where the work lives and what the helper was asked to do. A fail has the run edit a file under src/ itself, skip the helper and do the Todo 1 work directly, or finish without the one-line reply. Whether a Worktree line appears is judged by the other graders, not here.
