---
type: tool_used
tool: Skill
input_match: '"skill"\s*:\s*"(?:[^"]*:)?honesty"'
min: 0
max: 1
arm: both
---

Behavior: the run makes at most one Skill call whose input names the honesty skill (a bare name or a plugin-prefixed name ending in :honesty). A second call fails the max of 1, so a repeat load across the three README.md steps fails the run. A session with zero calls passes, because nothing was loaded twice; whether the skill is loaded at all is measured by the session-bootstrap-honesty-communication-order case. The check counts calls and matches the skill name in the JSON input, so no judge is needed. Known gaps: it does not check order or timing relative to session-bootstrap or the other skill. SKILL.md requires honesty and communication to be loaded again after compaction or --resume, and that correct second load fails the max of 1. The never-twice side is untriggered: no measured session loaded the skill twice, so a failure here is not yet seen.
