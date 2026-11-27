---
type: tool_used
tool: Bash
input_match: 'wc\s+(-\w*w|--words)'
min: 2
---

Pass: the session has at least two Bash calls whose command runs wc with a word flag (-w, -lw or --words). Fail: fewer than two such calls, for example one run, or runs of wc -l or other counts only. This grader counts runs at any point in the session; the llm grader over the trace checks that the runs come before the Agent call and cover both a passing and a failing input.
