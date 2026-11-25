---
type: tool_used
tool: Write
min: 0
max: 0
---

Never-does check: the run makes no Write call, because a comment from the user is answered with a proposal and the fix waits for the user's answer. The count comes from the tool name alone.

Limitation: a zero-count check passes a run that does nothing at all. The paired graders `checked-the-code` and `states-check-assessment-proposal` require the work and the posted reply. A change made through a Bash redirect or sed is not a Write call; `no-git-commit` covers the committed form of such a change.
