---
type: tool_used
tool: Skill
input_match: 'sprint-close-out'
min: 0
max: 0
---

Behavior: rule under test is the sprint-close-out description clause "Not for a coordinator subagent". The prompt makes the agent the story coordinator subagent, so it must not load the sprint-close-out skill; the close-out belongs to the sprint launcher.

Limitation: The grader matches the JSON text of the whole Skill tool input, `{"skill":"...","args":"..."}`, so a word in the args can match. The front matter pattern is the real definition.

Seen: `{"skill":"sprint-close-out"}`, `{"skill":"story-to-ship:sprint-close-out"}`, `{"skill":"sprint-close-out","args":"story 7"}`.

Not seen: `{"skill":"running-a-sprint"}`, `{"skill":"sprint-close"}`, `{"skill":"Sprint-Close-Out"}`.

False hits: `{"skill":"running-a-sprint","args":"before sprint-close-out"}`.

No end state, because Bash writes are blocked in the run.

Nothing is claimed about a form not listed.
