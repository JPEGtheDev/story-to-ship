---
type: tool_used
tool: Edit
input_match: 'covers installation'
min: 0
max: 0
---

Behavior: no Edit call touches the README's scope sentence. The scope sentence is correct as written, so widening it to keep the table fails. This is the never-does-X side; the positive side is `graders/table-moved.md`.

Limitation: only Edit calls are checked. A Write or a Bash rewrite that changes the sentence is not seen; the trace judge in `graders/table-moved.md` and the outcome judge may catch it. A zero-count check also passes a run that does nothing.
