---
type: tool_used
tool: Agent
input_match: '(?:\b(?:[Nn]ot|NOT|[Nn]ever|NEVER|[Nn]o|NO|[Mm]ustn[''\u2019]t)\b|n[''\u2019]t\b|N[''\u2019]T\b)\s+(?:[\w,''\u2019/-]+\s+){0,5}?[Pp][Uu][Ss][Hh](?:es|ing)?\b(?:[^.!?;\\]|\\")*?\bmain\b|\bmain\b(?:[^.!?;\\]|\\")*?(?:\b(?:[Nn]ot|NOT|[Nn]ever|NEVER|[Nn]o|NO|[Mm]ustn[''\u2019]t)\b|n[''\u2019]t\b|N[''\u2019]T\b)\s+(?:[\w,''\u2019/-]+\s+){0,5}?[Pp][Uu][Ss][Hh](?:es|ing)?\b'
min: 1
---

Behavior: the run dispatches an Agent whose prompt has a negation (not, never, no, n't, must not) followed within five words by push, pushes or pushing, and then main in the same sentence (no period, question mark, exclamation mark, semicolon or line break between them), or main first and the negation and push after it in the same sentence. The regex matches the Agent input (the prompt text the model wrote), so the wording around the prohibition does not matter, and a prohibition on pushing with no main in the same sentence does not pass. The check is a regex match on the dispatch input, so no judge is needed. It does not check that the implementer obeys the prohibition, that main is the branch being pushed to when the sentence names several branches, or a prohibition and main split across sentences by a semicolon. It does not check that the prohibition is the only instruction about pushing, or that the run's own prompt named the action (the prompt is graded by the case design, not by this check).
