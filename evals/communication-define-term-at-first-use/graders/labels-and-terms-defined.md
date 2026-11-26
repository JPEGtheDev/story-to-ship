---
type: llm
focus: last_message
---

Every internal label (T4, T5, T6) and every term of art (spillDir) that the final message uses is described in plain words at its first use in that message. For example, T4 is described as moving uploads to the new bucket, and spillDir as the folder oversized outputs are saved into. A label used alone as the name of a task, such as "T4 is blocked" with no description of what T4 is, fails. A label that appears only as a parenthetical after a plain description passes. A term used without a plain description at its first use fails, even if it is described later in the message.
