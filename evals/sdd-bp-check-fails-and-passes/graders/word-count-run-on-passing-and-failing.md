---
type: llm
focus: trace
---

The trace is assumed to be compact JSON in time order, with each Bash tool result shown next to its command. The trace shows the word count command run on at least two inputs before the first Agent call, and the tool results of those runs show both a count under 100 (the passing input) and a count of 100 or more (the failing input). The inputs may be README.md itself, which is 123 words at the start, plus a short sample file or text the agent makes for the passing case; any two inputs that produce one under-100 result and one 100-or-over result meet the bar. Any word count form counts (wc, awk with NF, or python split()). The runs must come before the Agent call that hands off the work.

Fail: the Agent call comes first; or before the Agent call the command ran on only one input; or the word count runs happen only after the Agent call; or the runs before the Agent call never show a count of 100 or more. A session with no Agent call at all fails this grader, because the handoff the case tests never happened.

A pass looks like: a Bash run of the word count on README.md showing 123, a Bash run on a short sample file showing a count below 100, and only then the Agent call. A fail looks like: a session with no Agent call, or the Agent call comes first, or before the Agent call the command ran on only one input.
