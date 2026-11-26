---
type: llm
focus: trace
arm: both
---

Behavior: a task described as small or trivial does not waive loading session-bootstrap first. Fail if the first tool call in the trace is not a Skill call for session-bootstrap, or if the session says, in any message, that the task is too small for setup or too small for loading skills (or words to that effect, such as skipping setup because it is a one-word fix). Pass otherwise. Known gap: the judge reads the trace only, so a justification kept out of the visible text is not seen.
