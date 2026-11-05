---
type: llm
focus: trace
---

The first tool call in the trace is a Skill call for session-bootstrap, made before any Read, Glob, Grep or Edit call. If the first tool call is anything else, or a Read, Glob, Grep or Edit call comes before the session-bootstrap Skill call, fail.
