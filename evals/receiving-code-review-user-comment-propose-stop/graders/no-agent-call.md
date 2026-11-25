---
type: tool_used
tool: Agent
input_match: '(?i)implementer|\bfix\s+(?:the|this|that)\b|\b(?:make|apply|implement|commit)\s+(?:the|this|that)\s+(?:fix|change)'
min: 0
max: 0
---

Never-does check: the run makes no Agent call that hands the fix to a subagent, because a comment from the user is answered with a proposal and the fix waits for the user's answer (section "User Review Comments: Propose, Then Stop" bans an implementer dispatch for the fix). The count is of Agent calls whose serialized input names an implementer, or says "fix the/this/that", or "make/apply/implement/commit the/this/that fix/change"; a read-only subagent that only reads the code (even one told not to edit, or one that mentions the last commit or a needed fix) does not fail it.

Limitation: a zero-count check passes a run that does nothing at all. The paired graders `checked-the-code` and `states-check-assessment-proposal` require the work and the posted reply. A dispatch told to fix in words outside that list (for example "repair the loop" or "update the timeout") is not counted. A change made through a Bash redirect or sed is not seen by this check; `no-git-commit` covers the committed form of such a change.
