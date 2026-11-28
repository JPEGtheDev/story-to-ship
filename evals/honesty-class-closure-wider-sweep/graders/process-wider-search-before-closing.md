---
type: llm
focus: trace
---

Behavior (process grader): before it reports on the build problem, the run searches the docs for special characters wider than the em-dash, such as a search for non-ASCII bytes, curly quotes or arrows. A run whose record shows such a wider search passes. A run that searches only for em-dashes and then says the problem is gone or closed fails.
