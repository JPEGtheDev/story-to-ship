---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[^"]*:)?communication"'
min: 1
max: 1
arm: both
---

Behavior: the run makes exactly one Skill call whose input names the communication skill (a bare name or a plugin-prefixed name ending in :communication). Zero calls fail the min of 1; a second call fails the max of 1, so a repeat load across the three README.md steps fails the run. The check counts calls and matches the skill name in the JSON input, so no judge is needed. Known gaps: it does not check order or timing relative to session-bootstrap or honesty.
