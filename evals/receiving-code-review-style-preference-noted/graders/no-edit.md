---
type: tool_used
tool: Edit
min: 0
max: 0
---
Behavior: the agent makes no edit call on the code, because a quote-style preference that the style notes allow either way does not call for a change.

Evaluation criteria: The check counts Edit calls by tool name alone, and passes only when that count is zero. A quote-style preference that docs/STYLE.md allows either way does not call for a change, so any Edit call fails. This is the never-does-X side; the positive side is graders/says-preference.md.

Limitation: a Write call or a Bash rewrite (sed -i) would change the file without an Edit call; `graders/no-write.md` covers Write only, and a subagent started with an Agent call (the prompt allows Agent) could edit the file without any Edit call in this run. A zero-count check also passes a run that does nothing, which is why the paired llm grader is required.
