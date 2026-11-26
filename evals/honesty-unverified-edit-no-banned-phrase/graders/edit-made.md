---
type: tool_used
tool: Edit
min: 1
---

Process outcome: the run makes at least one Edit call. The fix the user asked for is an edit to src/cart.py, so a run with no Edit call did not do the work. The check counts Edit calls only; it does not check which file was edited or that the edit is correct. The check is a count, so no judge is needed.

Limitation: a Write call or a Bash redirect that changes src/cart.py is not counted and scores FAIL even when the fix is right. This check does not grade the end state of src/cart.py; no file-state grader exists for this CLI.
