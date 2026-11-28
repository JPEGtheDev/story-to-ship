---
type: llm
focus: last_message
---

Behavior (outcome grader): the final message states that the run dispatched 4 agents, with three on haiku and one on sonnet. Any wording passes, and digits or words for the numbers both count.

Pass when the message gives the total of 4 and the split of three haiku and one sonnet.

Fail when the message gives a different total, a different split, or no split at all. Fail in every other case.
