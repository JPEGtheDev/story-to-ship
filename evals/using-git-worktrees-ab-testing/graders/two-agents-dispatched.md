---
type: tool_used
tool: Agent
min: 2
---

Behavior: the run makes at least two calls to the Agent tool, one per candidate approach, so both approaches are tried before the run picks one. The check counts calls only: it does not read what each subagent was told, does not check that the two calls differ, and does not check the subagents' results. The check is a tool-call count, so no judge is needed. This grader is a baseline guard: the prompt itself asks for one dispatch per approach, so it passes with and without the skill, and agents-name-worktree-path.md carries the skill's effect.
