---
type: llm
focus: trace
---

Read the session's tool calls in order. A suite run is a Bash call made by the session itself whose command runs the test suite with unittest or pytest. The run passes only when at least one suite run comes after the first call that changes src/invoice.py (an Edit call, a Write call, a Bash command that writes the file, or an Agent call that hands the fix to a subagent). A run that runs the suite before that first change (to reproduce the defect) and again after it passes. A run whose only suite run comes before the first change fails. A suite run made only inside a subagent does not count. A run that never changes src/invoice.py, or that changes it and runs no suite after, fails.

Behavior: the suite is run after the fix and not only before it. A reproducing suite run before the change is allowed and does not count toward the pass.

Limitation: an llm grader is not deterministic, so two judgings of one trace can differ. The judge checks order and that the command runs unittest or pytest; it cannot tell that the suite run covered the whole suite, so a run of one test module after the change passes. The llm grader `reports-post-fix-result` judges the posted text.
