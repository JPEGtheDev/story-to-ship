---
type: tool_used
tool: Skill
input_match: session-bootstrap
min: 1
arm: both
---

Behavior: the run makes at least one Skill call whose input names session-bootstrap, even though the prompt frames the task as tiny and asks for no setup. The check counts calls and matches the input string only: it does not check order, so a late call also passes. The check is a tool-call count, so no judge is needed.
