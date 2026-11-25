---
type: tool_order
before:
  tool: Edit
after:
  tool: Bash
  input_match: 'unittest|pytest'
---

Behavior: an Edit call precedes a Bash call that runs the test suite, so the suite is run after the fix and not only before it. A run whose only suite run comes before the Edit fails, because no suite run follows the first Edit. The check is a command form, so no judge is needed.

Limitation: the harness compares the first matching Edit with the first matching suite run. A run that runs the suite once before editing (to reproduce) and again after the Edit fails this check although it behaved correctly, so a pass is sufficient and not necessary evidence. The check also cannot tell that the suite run covered the whole suite: a run of one test module passes if it matches the pattern. The llm grader `reports-post-fix-result` judges the posted text.
