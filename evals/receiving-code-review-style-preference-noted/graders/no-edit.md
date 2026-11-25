---
type: tool_used
tool: Edit
min: 0
max: 0
---

Behavior: the run makes no Edit call. A quote-style preference that docs/STYLE.md allows either way does not call for a change, so any Edit fails. This is the never-does-X side; the positive side is `graders/says-preference.md`.

Limitation: a Write call or a Bash rewrite (sed -i) would change the file without an Edit call; `graders/no-write.md` covers Write only. A zero-count check also passes a run that does nothing, which is why the paired llm grader is required.
