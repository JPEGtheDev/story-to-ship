---
type: tool_used
tool: Agent
input_match: '"subagent_type"\s*:\s*"(?:[\w-]+:)?implementer"'
max: 0
---

Behavior: a read-only search job is never handed to the implementer type. The grader passes when no Agent call names the implementer type in its subagent_type field. The implementer type counts whether bare or with an optional plugin prefix such as story-to-ship:implementer. The optional prefix covers the plugin-namespaced form; how a real plugin-loaded session names its agent types is unconfirmed, and the grader assumes only that the prefixed form is possible. It fails when any Agent call names the implementer type, even if the search still finds the right modules.
