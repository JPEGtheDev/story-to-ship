---
type: tool_used
tool: Edit
min: 1
arm: both
---

Behavior: the run makes at least one Edit call, so the task the prompt asks for is done. Known gaps: the check counts Edit calls only and does not read what the edit changed, so a session that writes the file only through Bash fails it even if the task is done. It confirms the session reached the work and did not stop at the check.
