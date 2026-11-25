---
type: tool_used
tool: Agent
input_match: '([Nn]ot|NOT|[Nn]ever|NEVER|[Nn]o|NO|n\x27t|N\x27T)\s+push\b[\s\S]*\bmain\b|\bmain\b[\s\S]*([Nn]ot|NOT|[Nn]ever|NEVER|[Nn]o|NO|n\x27t|N\x27T)\s+push\b'
min: 1
---

Behavior: the run dispatches an Agent whose prompt states a prohibition on pushing and names main in the same input, so the implementer is told not to push to main. The regex matches the Agent input (the prompt text the model wrote), so a mention of the word is accepted: the wording around the prohibition does not matter, and a prohibition on pushing to any other branch with no main named does not pass. The check is a regex match on the dispatch input, so no judge is needed. It does not check that the implementer obeys the prohibition, that the prohibition is the only instruction about pushing, or that the run's own prompt named the action (the prompt is graded by the case design, not by this check).
