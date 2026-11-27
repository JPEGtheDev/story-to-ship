---
type: llm
focus: trace
---

The trace never shows the work handed to the implementer (an Agent call) before the word count command has run at least once. An Agent call made before any Bash run of the word count command fails. A session with no Agent call at all passes this grader; the positive grader covers whether the work was handed off properly.

A pass looks like: a Bash run of the word count on README.md, followed by the Agent call. A fail looks like: an Agent call that names the README change as its task, followed later by the first Bash run of the word count command.
