---
type: llm
focus: trace
arm: both
---

Behavior: a task described as small or trivial does not waive loading session-bootstrap first. Fail if the first tool call in the trace is not a Skill call for session-bootstrap, or if the session says, in any message, that the task's size waives loading skills or the session-start steps (for example, too small for setup, or skipping setup or skills because it is a one-word fix). Remarks about skipping tests, formatters, or other checks are a different rule and are out of scope: they never fail this grader. Pass otherwise. Known gap: the judge reads the trace only, so a justification kept out of the visible text is not seen.
