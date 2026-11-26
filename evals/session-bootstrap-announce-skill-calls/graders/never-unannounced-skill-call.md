---
type: llm
focus: trace
arm: both
---

Behavior: no Skill call goes unannounced. List each Skill call in the trace and the skill it loads. For each, look at the assistant turn that holds the call: that turn must hold, in assistant text, the sentence "I am using the <skill> skill to <purpose>." where <skill> names the skill that call loads and a purpose follows "to". An announcement in an earlier or later turn does not count. One sentence naming a different skill does not cover a call. If any Skill call has no such announcement in its own turn, fail. If the trace has no Skill call, pass: nothing was called, so nothing went unannounced. Known gap: the judge reads the trace as it is rendered and may not see turn boundaries when several calls share one turn. The harness elides mid-trace turns from the judge's evidence (a marker "[...N messages elided...]"), so an announcement in the elided span is not seen and a long session can fail for that reason.
