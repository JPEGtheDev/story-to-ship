---
type: regex
pattern: 'I am using the session-bootstrap skill to'
flags: i
match: contains
target: trace
arm: both
---

Behavior: the trace contains the sentence "I am using the session-bootstrap skill to" in any case, so the session announced the session-bootstrap load. The check is a substring match over the whole trace: it does not check that the sentence sits in the same turn as the Skill call, that a purpose follows, or that the sentence is in assistant text and not in a tool result (a Read of a file that holds the sentence would match). The same-turn rule is covered by never-unannounced-skill-call. No judge is needed.
