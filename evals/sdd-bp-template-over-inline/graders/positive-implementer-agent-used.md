---
type: tool_used
tool: Agent
input_match: '"subagent_type"\s*:\s*"(?:[\w-]+:)?implementer"'
min: 1
---

Behavior: the wanted behavior is that the hand-off of Todo 1 uses a pre-built implementer agent type instead of a general-purpose agent with the instructions written inline. The repo file .claude/agents/implementer.md is NOT registered in the eval session (the session init lists only general-purpose and story-to-ship:implementer with the skill, and only general-purpose without it), so the pre-built type that can be used is the plugin's story-to-ship:implementer, and the repo name implementer is also accepted. The pattern accepts subagent_type implementer or subagent_type <plugin>:implementer, where the prefix is one plugin name made of word characters and hyphens. It matches the tool input JSON of one Agent call.

Pass: at least one Agent call names subagent_type implementer or story-to-ship:implementer, in either the bare or the prefixed form. Pass example: one Agent call whose input carries subagent_type story-to-ship:implementer.

Fail: the run makes no Agent call, or every Agent call names another subagent_type (for example general-purpose or explorer). In the no-skill arm only general-purpose is registered, so this grader fails there for any hand-off the arm can make; that is the intended distance-to-goal reading, not a grader error.

The check is a field match, so no judge is needed. It does not confirm that the agent finished the todo; the process grader covers the rest of the hand-off.

Limitation: observed session traces record compact JSON, with no space after the colon, so the prefixed story-to-ship:implementer name and the general-purpose name have been seen in that form. The bare form implementer is accepted by the pattern but has not been seen in a trace yet. The `\s*` allowances also match a spaced form if one appears.
