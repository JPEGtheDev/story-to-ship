---
type: tool_used
tool: Agent
input_match: '"subagent_type"\s*:\s*"implementer"'
min: 1
---

Behavior: when the repo holds a pre-built implementer definition in .claude/agents/, the hand-off of Todo 1 goes to an agent that uses that definition, so the Agent call names subagent_type implementer. The pattern matches the tool input JSON of one Agent call. A run that hands the todo off with subagent_type implementer passes. A run that makes no Agent call, or one with any other subagent_type, fails this grader. The check is a field match, so no judge is needed. It does not confirm that the agent finished the todo; the process grader covers the rest of the hand-off.

Limitation: the pattern assumes the compact JSON form `"subagent_type":"implementer"`, which is unconfirmed against a real trace; a run that writes the same field with a space after the colon still matches because of the `\s*` allowances.
