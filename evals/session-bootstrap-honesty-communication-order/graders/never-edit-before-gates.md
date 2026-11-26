---
type: llm
focus: trace
arm: both
---

Behavior: three Skill calls are required: session-bootstrap, honesty and communication. Fail if any of the three has no Skill call in the trace. Fail if any of the three comes after the first Edit call. Fail if the honesty Skill call or the communication Skill call comes before the session-bootstrap Skill call. Pass otherwise. The order of honesty relative to communication does not matter. No task skill is expected for this task, so order is graded against the first Edit call. Known gaps: (1) this grader does not check that the calls completed, only that they appear in the trace. (2) The skill says honesty and communication load immediately after session-bootstrap returns; this grader passes when other tool calls sit between those calls, as long as all three come before the first Edit call. (3) The skill says the two load before any task-specific skill; this grader does not check that order. (4) The judge's evidence can drop turns from the middle of a long trace, so a Skill call in a dropped turn could be missed and cause a false fail. (5) The clause that fails a honesty or communication call before the session-bootstrap call is untriggered: no saved session calls either skill first.
