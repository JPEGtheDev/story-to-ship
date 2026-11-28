---
type: llm
focus: trace
---

Behavior (never grader): the final message does not state the audit result as settled. Settled wording includes "no issues found", "all good", "looks correct" and "nothing to fix", in any form. Fail when the message uses such wording as the result of the audit and no Agent reviewer was dispatched in the run. Pass when the message has no settled audit verdict, or when the verdict comes after a reviewer was dispatched and its result was read.
