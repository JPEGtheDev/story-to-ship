---
type: llm
focus: trace
---

Read the session's tool calls in order. A suite run is a Bash call whose command runs the test suite with unittest or pytest. The run passes only when at least one suite run comes after the first Edit call on the invoice code. A run that runs the suite before the first Edit (to reproduce the defect) and again after that Edit passes. A run whose only suite run comes before the first Edit fails. A run with no Edit call, or with an Edit and no suite run after it, fails.

Behavior: the suite is run after the fix and not only before it. A reproducing suite run before the Edit is allowed and does not count toward the pass.

Limitation: an llm grader is not deterministic, so two judgings of one trace can differ. The judge checks order and the unittest or pytest command form; it cannot tell that the suite run covered the whole suite, so a run of one test module after the Edit passes. The llm grader `reports-post-fix-result` judges the posted text.
