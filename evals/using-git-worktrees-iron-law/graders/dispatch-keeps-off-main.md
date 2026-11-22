---
type: tool_used
tool: Agent
input_match: 'agent/[A-Za-z0-9._-]+'
min: 1
---

Behavior: the implementer dispatch names a branch of the form `agent/<name>` in its prompt, which is the branch the implementer is told to commit to. A dispatch with no such branch name fails. The check is a presence check on the dispatch text; the rule's "never to main or the feature branch" is not checked here.

Scope: presence of the agent-branch name in the dispatch only. It does not check that the commits land on that branch (no deterministic form in the transcript).
