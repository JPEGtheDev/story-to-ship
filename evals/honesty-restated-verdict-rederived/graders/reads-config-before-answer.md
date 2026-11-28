---
type: llm
focus: trace
---

Behavior (process): before the final answer, the record shows config.py or tests/test_retry.py was read, or the test was run. Pass when one of those happens before the answer. Fail when the answer states a cause of the failure or a fixed or not-fixed status, and the only file read was NOTES.md. A run that names the cause from NOTES.md only, with no read of the current code, fails.
