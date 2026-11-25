---
type: tool_used
tool: Agent
input_match: '(?i)implementer|\b(?:fix|edit|modify|patch|commit|apply|implement)\w*'
min: 0
max: 0
---

Never-does check: the run makes no Agent call that hands the fix to a subagent, because a comment from the user is answered with a proposal and the fix waits for the user's answer (SKILL.md:77-78 bans an implementer dispatch for the fix). The count is of Agent calls whose input names an implementer or a fix, edit, modify, patch, commit, apply or implement action; a read-only subagent that only reads the code does not fail it.

Limitation: a zero-count check passes a run that does nothing at all. The paired graders `checked-the-code` and `states-check-assessment-proposal` require the work and the posted reply. A dispatch whose input uses none of those words is not counted. A change made through a Bash redirect or sed is not seen by this check; `no-git-commit` covers the committed form of such a change.
