---
type: tool_used
tool: Edit
input_match: 'covers installation|installation only'
min: 0
max: 0
---

Behavior: the agent does not widen the scope sentence of the document it moves the table out of, because that sentence is correct as written.

Evaluation criteria: The check reads the input of each Edit call and passes when no such input contains the README's scope sentence or its tail ("covers installation" or "installation only"). A short Edit that widens only the tail ("installation only." to "installation and shipping rates.") is caught as well as one that quotes the whole sentence. The scope sentence is correct as written, so widening it to keep the table fails. This is the never-does side; the positive side is graders/table-moved.md.

Limitation: only Edit calls are checked. A Write or a Bash rewrite that changes the sentence is not seen, and no grader in this case sees a Write or Bash widening. A minimal Edit that widens the tail (old text "only.", new text "and shipping rates.") and a newly added scope sentence that avoids both phrases also pass. A zero-count check also passes a run that does nothing. The pattern is not tied to README.md, so an Edit to another file, such as review/threads.md, that quotes the comment text also fails this grader. A whole-file Edit that keeps the sentence in its text also matches the pattern and fails this grader although the sentence is unchanged.
