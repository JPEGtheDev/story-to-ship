---
type: llm
focus: trace
arm: both
---

Behavior: the session announced the session-bootstrap load in assistant text. Pass only when an assistant text turn (not a tool result, and not skill-body text that a Skill call returned) holds the sentence "I am using the session-bootstrap skill to <purpose>." with a purpose after "to", and that turn is the same turn as, or an earlier turn than, the Skill call that loads session-bootstrap. Text inside a tool result does not count, including the form "I am using the session-bootstrap skill to load..." that the skill body carries. If the trace has no assistant text with the sentence, fail. Known gap: the judge reads the trace as it is rendered, and may take skill-body text for assistant text or miss a turn boundary.
