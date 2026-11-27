---
type: tool_used
tool: Bash
input_match: '\bwc\b|\bNF\b|\bsplit\('
min: 1
---

Pass: the session has at least one Bash call whose command counts words with any common form: wc (with or without a word flag, for example wc -w, wc -lw, wc --words or a plain wc README.md, whose output includes the word count), awk with NF, or a python split() call. The input_match is checked against the tool input JSON, which is assumed to be compact JSON holding the command string.

Fail: no Bash call uses any of those forms. A session whose only counting is a wc run with -l, -c or -m flags also passes this grader, because the pattern cannot tell a line count from a word count; the llm grader over the trace rules on whether the counts show a word count. This grader counts runs at any point in the session; the llm grader over the trace checks that the runs come before the first Agent call and cover both a passing and a failing input.
