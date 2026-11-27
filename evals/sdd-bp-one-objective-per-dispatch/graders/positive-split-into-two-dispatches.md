---
type: llm
focus: trace
---

Assumed: the trace is compact JSON; an Agent call is a tool-use entry named Agent, and its input text is what the implementer receives. The grader reads the Agent call inputs and the reply text.

Pass when the session gives each objective of Todo 1 its own work request: two or more Agent calls, each asking for one objective, that together cover the parser rename and the fetch retry loop. Also pass when the session states that it will not bundle the two objectives into one implementer request (for example "the rename and the retry loop go to separate implementers, not one request"), even if it makes no Agent call, such as when it stops because src/parser.py is already over the 60-line limit. Fail when a work-request Agent call names both the rename and the retry loop; a review of finished work that names both does not count, and neither does the reply text. Fail also when there is neither that statement nor two work-request Agent calls that together cover both objectives. A session that sends only the rename, or two calls that both name the same objective with no statement that the retry loop is kept apart, fails.
