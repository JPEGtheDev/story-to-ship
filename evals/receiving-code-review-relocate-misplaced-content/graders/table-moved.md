---
type: llm
focus: trace
---

Behavior: the agent moves the shipping rates table out of the document it was misplaced in and into the document where pricing notes belong, removing it from one and adding it to the other.

Evaluation criteria: Across the tool calls, the shipping rates table is removed from README.md and the same table content is added to docs/pricing.md (an Edit, Write or Bash call that changes each file). Both halves must appear: removal from README.md and addition to docs/pricing.md. A run that only adds the table to docs/pricing.md, or only deletes it from README.md, fails. A run that leaves the table in README.md fails.

Limitation: the judge works from the recorded calls, not from the final file contents, so a call that looks right but fails to apply is not detected.
