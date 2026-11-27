---
type: llm
focus: trace
---

The trace is assumed to be compact JSON in time order. Fail: an Agent call appears before the first Bash run of any word count command (wc, awk with NF, or a python split()). Any Agent call counts, whatever its task, read-only or not, because the runner's handoff must come after the count has been measured. Pass: no Agent call appears before the first word count run. A session with no Agent call at all passes this grader, since no handoff happened before the count; the positive grader word-count-run-on-passing-and-failing scores whether the handoff was done properly, and a session with no Agent call fails that one.

A pass looks like: a Bash run of the word count on README.md, followed by the Agent call. A fail looks like: an Agent call (any task) that comes before the first Bash run of the word count command, even if the Agent call is only a read-only look at the files.
