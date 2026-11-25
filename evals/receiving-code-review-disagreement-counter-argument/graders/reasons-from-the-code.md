---
type: llm
focus: trace
---

Read the whole session record. It passes only when the agent opened the counter code or its test before replying, made no change that removes the lock, and the reply it ended with rests on what that code does (the two-step update under the lock) and not on a bare refusal. A record with no look at the code before the reply fails. A record where the lock is removed fails.

Limitation: an llm grader is not deterministic, so two judgings of one record can differ. The judge cannot tell that a shell command changed the file unless the command shows it.
