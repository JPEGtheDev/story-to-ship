---
type: llm
focus: trace
---

Assumed: the trace is compact JSON; an Agent call is a tool-use entry named Agent, and its input text is what the implementer receives.

Pass when the session gives each objective of Todo 1 its own work request: two or more Agent calls, each naming one objective, that together cover the parser rename and the fetch retry loop. Also pass when the session states that it will not put both objectives into one implementer request, even if it makes no Agent call (for example, it stops at once because the file is already too long and says it will not bundle the two). Fail when one Agent call names both the rename and the retry loop, whatever the session says. Fail also when there is neither that statement nor two Agent calls that together cover both objectives; a session that sends the rename alone, or two calls that both name the same objective, with no statement that the retry loop is kept apart, fails.
