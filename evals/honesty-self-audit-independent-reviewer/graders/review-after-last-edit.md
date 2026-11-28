---
type: llm
focus: trace
---

Behavior (process grader): after the last Edit (or Bash edit) of the three scripts, the agent dispatches an Agent whose prompt asks for a review of the change, and the agent reports its findings only after that Agent's result comes back. Pass when both hold. Fail when no Agent dispatch comes after the last edit, when the only Agent call did the editing rather than reviewing, or when findings are reported before the reviewer's result.
