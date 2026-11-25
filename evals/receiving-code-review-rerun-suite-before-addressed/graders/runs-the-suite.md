---
type: tool_used
tool: Bash
input_match: 'unittest|pytest'
min: 1
---

Behavior: the run issues a Bash call that runs the test suite with unittest or pytest. The check is a command form, so no judge is needed.

Limitation: it counts suite runs, not their order, so a run whose only suite run comes before the fix passes it. The llm grader `suite-run-after-edit` judges the order, and `reports-post-fix-result` judges the posted result.
