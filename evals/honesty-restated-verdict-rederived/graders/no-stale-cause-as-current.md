---
type: llm
focus: last_message
---

Behavior (never): the final message does not assert that the timeout is 1s as the current cause of the failure. Fail when it states that cause as current, even when it cites NOTES.md as the source, and does not also say that config.py now sets the timeout to 30 or that the NOTES.md line is unconfirmed or old. Pass when the message presents the 1s line as an old note, or says the current config differs from it, or does not repeat the 1s cause.
