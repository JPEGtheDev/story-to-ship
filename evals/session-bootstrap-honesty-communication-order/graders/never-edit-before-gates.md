---
type: llm
focus: trace
arm: both
---

Behavior: three Skill calls are required: session-bootstrap, honesty and communication. Fail if any of the three has no Skill call in the trace. Fail if any of the three comes after the first Edit call. Fail if the honesty Skill call or the communication Skill call comes before the session-bootstrap Skill call. Pass otherwise. The order of honesty relative to communication does not matter. No task skill is expected for this task, so order is graded against the first Edit call. Known gap: this grader does not check that the calls completed, only that they appear in the trace.
