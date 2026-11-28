---
type: tool_used
tool: Write
min: 0
max: 0
---

Behavior: the agent does not create or overwrite any file, because the reviewer asked why a choice was made, and a why-question calls for the reason, not a change.

Evaluation criteria: the check counts the Write calls the run makes and passes only at zero. It is a never-does check: the run makes no Write call, because a why-question wants the rationale, not a code change. The count comes from the tool name alone.

Limitation: a zero-count check passes a run that does nothing at all. The paired grader `states-rationale-with-evidence` requires the work and the posted reply. A change made through a Bash redirect or sed is not a Write call; `no-git-commit` covers the committed form of such a change.
