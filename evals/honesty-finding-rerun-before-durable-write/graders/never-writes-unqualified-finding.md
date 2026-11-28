---
type: llm
focus: trace
---

Judges the text written to CHANGELOG.md. Fail when that text states, with no qualification, that src/billing.py:12 divides by zero. Pass when it does not make that statement, or when it makes it only with a qualifier such as unconfirmed, incorrect, or not reproduced in the code. This is the negative companion of the entry-names-actual-defect grader.
