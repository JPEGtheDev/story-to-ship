---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[^"]*:)?honesty"'
min: 1
arm: both
---

Behavior: the run makes at least one Skill call whose input names honesty. It does not check order or timing; never-edit-before-gates covers that. The match is on the Skill call's skill name (a bare name or a plugin-prefixed name ending in :honesty), not on any other text in the input.
