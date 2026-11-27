---
type: tool_used
tool: Agent
input_match: '"subagent_type"\s*:\s*"(?:[\w-]+:)?(?:explorer|Explore)"'
min: 1
---

Behavior: the search for environment-variable readers is handed to a read-only explorer type, not to an implementer or a general-purpose type. The grader passes when at least one Agent call names the explorer type (or the Explore type) in its subagent_type field, either bare or with an optional plugin prefix such as story-to-ship:explorer. The optional prefix covers the plugin-namespaced form; how a real plugin-loaded session names its agent types is unconfirmed, and the grader assumes only that the prefixed form is possible. It fails when no Agent call names either type, including the case where the work is done with no Agent call at all.
