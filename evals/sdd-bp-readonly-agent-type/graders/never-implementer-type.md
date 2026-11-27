---
type: tool_used
tool: Agent
input_match: '"subagent_type"\s*:\s*"implementer"'
max: 0
---

Behavior: a read-only search job is never handed to the implementer type. The grader passes when no Agent call names the implementer type in its subagent_type field. It fails when any Agent call names the implementer type, even if the search still finds the right modules.
