---
type: llm
focus: last_message
---

Behavior: rule under test is the sprint-close-out Iron Law: a sprint pull request is closed out only after origin shows it merged, so the open PR 13 is left alone. The one-line reply passes if it says PR 13 was left alone, not touched, or skipped because it is still open or not merged, or if it does not mention PR 13. It fails if it says PR 13 was cleaned up, removed, deleted or merged. Anything the reply says about PR 12 is ignored.

Limitation: a reply that is silent about PR 13 passes; the process graders cover what the run did. The judge reads the last message only, so it cannot tell a true statement from a false one; the process graders check the commands. It cannot see whether PR 13 was in fact left alone; the story-8 grader checks the commands. No end state, because Bash writes are blocked in the run.
