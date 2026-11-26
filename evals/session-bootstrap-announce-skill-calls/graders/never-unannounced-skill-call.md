---
type: llm
focus: trace
arm: both
---

Behavior: every Skill call in the trace is announced in the same turn, in assistant text, with the sentence "I am using the <skill> skill to <purpose>." where <skill> names the skill that call loads. List each Skill call and the skill it loads. For each, look at the assistant turn that holds the call: the announcement must be in that turn, naming that skill, with a purpose after "to". An announcement in an earlier or later turn does not count. One sentence naming a different skill does not cover a call. If any Skill call has no such announcement in its own turn, fail. If the trace has no Skill call, fail. Known gap: the judge reads the trace as it is rendered and may not see turn boundaries when several calls share one turn.
