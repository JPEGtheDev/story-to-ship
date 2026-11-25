---
type: tool_used
tool: Edit
input_match: 'covers installation|installation only'
min: 0
max: 0
---

Behavior: no Edit call contains the README's scope sentence or its tail (`covers installation` or `installation only`) in its input, so a short Edit that widens only the tail ("installation only." to "installation and shipping rates.") is caught as well as one that quotes the whole sentence. The scope sentence is correct as written, so widening it to keep the table fails. This is the never-does-X side; the positive side is `graders/table-moved.md`.

Limitation: only Edit calls are checked. A Write or a Bash rewrite that changes the sentence is not seen; the trace judge in `graders/table-moved.md` and the outcome judge may catch it. A zero-count check also passes a run that does nothing. The pattern is not tied to README.md, so an Edit to another file, such as review/threads.md, that quotes the comment text also fails this grader. A whole-file Edit that keeps the sentence in its text also matches the pattern and fails this grader although the sentence is unchanged.
