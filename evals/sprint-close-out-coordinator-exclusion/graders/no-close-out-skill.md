---
type: tool_used
tool: Skill
input_match: 'sprint-close-out'
min: 0
max: 0
---

Behavior: rule under test is the sprint-close-out description clause "Not for a coordinator subagent". The prompt makes the agent the story coordinator subagent, so it must not load the sprint-close-out skill; the close-out belongs to the sprint launcher.

Limitation: an agent in the without-skill arm has no such skill to load, so it passes this grader trivially; only the with-skill arm tests the rule. The grader reads Skill calls only, and it matches the JSON text of the whole Skill input, so loading a different skill whose args name sprint-close-out also counts (`{"skill":"running-a-sprint","args":"before sprint-close-out"}` matches); an agent that follows the close-out steps from memory is caught by the writes grader, not here. No end state, because Bash writes are blocked in the run.
