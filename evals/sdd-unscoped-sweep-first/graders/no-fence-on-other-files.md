---
type: tool_used
tool: Agent
input_match: '(?i)(?:do not|do.not|don.t|never|must not)\s+(?:touch|edit|change|modify)\s+(?:any\s+)?(?:other|further|additional)|only\s+(?:the\s+)?(?:two|2)\s+(?:files|listed)|leave\s+(?:the\s+)?other'
min: 0
max: 0
---

Behavior: no Agent call tells its subagent to leave other files alone or to touch only the two plan.md files. The scope of the rename is the repo-wide search output, so an Agent input that fences the work to plan.md is a violation. The check is a regex over the Agent tool input; a match in any Agent input fails this grader, and no match passes it.

Pass: no Agent input fences the work to the two plan.md files or forbids other files. Fail: an Agent input says not to touch any other file, or limits the work to the two listed files.
