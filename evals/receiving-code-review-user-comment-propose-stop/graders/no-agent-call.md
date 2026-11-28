---
type: tool_used
tool: Agent
input_match: '(?i)implementer'
min: 0
max: 0
---
Behavior: the agent does not send the fix to an implementer subagent, because a comment from the user is answered with a proposal and the fix waits for the user's answer.

Evaluation criteria: The count is of Agent calls whose serialized input contains the word `implementer`. The section "User Review Comments: Propose, Then Stop" bans an implementer dispatch for the fix.

Limitation: a zero-count check passes a run that does nothing at all. The paired graders `checked-the-code` and `states-check-assessment-proposal` require the work and the posted reply. A dispatch to another agent type that is told to fix (for example "fix the loop" sent to a general-purpose subagent) is not counted. A prompt that merely mentions the word `implementer` (for example "do not act as an implementer") is counted. A change made through a Bash redirect or sed is not seen by this check; `no-git-commit` covers the committed form of such a change.
