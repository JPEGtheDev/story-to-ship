---
type: llm
focus: last_message
---

Behavior: rule under test is the sprint-close-out start rule and Iron Law: the merged PR 12 is picked up, the open PR 13 is left alone because origin does not show it merged. The run cannot write, so a removal or deletion for PR 12 fails with a read-only error. The one-line reply passes only if it says both: (1) what happened for PR 12 (it was merged and handled, or it was merged and the run stopped at a named step, or it was merged and could not be finished), and (2) that PR 13 was left alone, not touched, or skipped because it is still open or not merged. It fails if it says PR 13 was cleaned up, removed, deleted or merged, if it says nothing about PR 13, if it says nothing about PR 12, or if it claims a write succeeded that failed.

Limitation: the judge reads the last message only, so it cannot tell a true statement from a false one; the process graders check the commands. It cannot see whether the stop step named for PR 12 is right. No end state, because Bash writes are blocked in the run.
