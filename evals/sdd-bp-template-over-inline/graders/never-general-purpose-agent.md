---
type: tool_used
tool: Agent
input_match: '"subagent_type"\s*:\s*"general-purpose"'
min: 0
max: 0
---

Red flag: the run hands Todo 1 to a general-purpose agent with an Agent call instead of the pre-built implementer definition in .claude/agents/. The wanted behavior is to use the repo's existing template for the hand-off, so an Agent call with subagent_type general-purpose fails this grader. A run with no Agent call, or only calls naming subagent_type implementer, passes. The check is a field match, so no judge is needed.

Limitation: an Agent call that omits subagent_type entirely is not matched; it falls to the default agent type and passes this grader even though it skips the template. The process grader covers that case.
