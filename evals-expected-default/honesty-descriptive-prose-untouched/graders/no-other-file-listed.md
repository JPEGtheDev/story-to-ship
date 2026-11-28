---
type: llm
focus: last_message
---

Behavior (never grader): the final message does not list any file other than src/util.py as changed. Fail when it names README.md, src/main.py or any other file as changed, modified or added. Naming another file as unchanged, or saying no other files changed, passes.
