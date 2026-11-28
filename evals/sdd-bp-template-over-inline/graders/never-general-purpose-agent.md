---
type: tool_used
tool: Agent
input_match: '"subagent_type"\s*:\s*"general-purpose"'
min: 0
max: 0
---

Red flag: the run hands Todo 1 to a general-purpose agent with an Agent call instead of a pre-built implementer agent type. The wanted behavior is that the hand-off uses the pre-built implementer type (repo name implementer, or the plugin's story-to-ship:implementer), so an Agent call that names subagent_type general-purpose fails this grader. The repo file .claude/agents/implementer.md is not registered in the eval session, so the registered implementer type is the plugin's; the no-skill arm has only general-purpose available, so this grader fails there for any hand-off it makes, which is the intended distance-to-goal reading. A run with no Agent call, or only calls naming subagent_type implementer or story-to-ship:implementer, passes. The check is a field match, so no judge is needed.

Limitation: an Agent call that omits subagent_type entirely is not matched; it falls to the default agent type and passes this grader even though it skips the pre-built type. The positive grader requires an implementer name, and the process grader covers the omitted-type case.
