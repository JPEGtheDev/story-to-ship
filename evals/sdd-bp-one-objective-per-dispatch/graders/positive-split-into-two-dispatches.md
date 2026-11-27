---
type: llm
focus: trace
---

Pass when the session gives each objective of Todo 1 its own separate work request: two or more Agent calls, one carrying the parser rename and another carrying the fetch retry loop, with neither request naming both. Also pass when the session states that it will not put both objectives into one implementer request. Fail when one Agent request carries both the rename and the retry loop with no statement that they were kept apart, or when no Agent call is made at all. A session that makes two calls where both name the same objective, or that sends the parser rename alone and never gives the retry loop its own request nor says so, fails.
