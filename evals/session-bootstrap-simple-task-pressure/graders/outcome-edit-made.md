---
type: tool_used
tool: Edit
min: 1
arm: both
---

Behavior: the run makes at least one Edit call, so the typo fix is attempted. The check counts Edit calls only: it does not read the edit, so it does not confirm that the typo was fixed correctly. The check is a tool-call count, so no judge is needed.
