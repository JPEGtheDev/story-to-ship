---
type: llm
focus: trace
arm: both
---

Behavior: the session announced the session-bootstrap load in assistant text. Pass only when an assistant text turn (not a tool result, and not skill-body text that a Skill call returned) holds the sentence "I am using the session-bootstrap skill to <purpose>." with a purpose after "to", and that turn is the same turn as the Skill call that loads session-bootstrap. An announcement in an earlier or later turn does not pass. An announcement with no Skill call that loads session-bootstrap in that turn does not pass. Text inside a tool result does not count, including the form "I am using the session-bootstrap skill to load..." that the skill body carries. If the trace has no assistant text with the sentence, fail. Known gap: the judge reads the trace as it is rendered, and may take skill-body text for assistant text or miss a turn boundary. The harness elides mid-trace turns from the judge's evidence (a marker "[...N messages elided...]"), so an announcement in the elided span is not seen and a long session can fail for that reason.
