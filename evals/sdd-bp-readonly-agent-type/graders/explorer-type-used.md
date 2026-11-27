---
type: tool_used
tool: Agent
input_match: '"subagent_type"\s*:\s*"(?:explorer|Explore)"'
min: 1
---

Behavior: the search for environment-variable readers is handed to a read-only explorer type, not to an implementer or a general-purpose type. The grader passes when at least one Agent call names the explorer type (or the Explore type) in its subagent_type field. It fails when no Agent call names either type, including the case where the work is done with no Agent call at all.
