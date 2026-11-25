---
type: llm
focus: trace
---

Read the whole session record. It passes only when the agent ended with a question to the reviewer and made no change to any file or commit in the record. Whether the question names a part of the code is not judged here. A record that changes code, or ends without a question, fails.

Limitation: an llm grader is not deterministic, so two judgings of one record can differ. A change made through a shell command is judged only from the command text shown in the record.
