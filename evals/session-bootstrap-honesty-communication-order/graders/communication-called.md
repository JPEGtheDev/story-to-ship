---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[^"]*:)?communication"'
min: 1
arm: both
---

Behavior: the run makes at least one Skill call whose input names communication. It does not check order or timing; never-edit-before-gates covers that. The match is on the Skill call's skill name (a bare name or a plugin-prefixed name ending in :communication), not on any other text in the input.
