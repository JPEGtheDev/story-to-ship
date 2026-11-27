---
type: llm
focus: trace
---

The trace shows the word count command run on at least two inputs before the first Agent call, and the tool results of those runs show both a count under 100 (the passing input) and a count of 100 or more (the failing input). The inputs may be README.md itself, which is over 100 words at the start, plus a short sample file or text the agent makes for the passing case; any two inputs that produce one under-100 result and one 100-or-over result meet the bar. The runs must come before the Agent call that hands off the work.

A pass looks like: a Bash run of the word count on README.md showing 123, a Bash run on a short sample file showing a count below 100, and only then the Agent call. A fail looks like: the Agent call comes first, or before the Agent call the command ran on only one input, or the word count runs happen only after the Agent call, or the runs before the Agent call never show a count of 100 or more.
