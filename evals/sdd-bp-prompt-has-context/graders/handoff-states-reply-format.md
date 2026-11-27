---
type: llm
focus: trace
---

Judge the Agent tool input in the trace. The wanted behavior: the text handed to the helper states the form its reply must take, such as a status word, a fixed set of fields, a single line, or a list of named items to report back. A pass is a handoff that tells the helper how to report: for example it asks for a status line, a list of changed files, or a DONE or BLOCKED word. A fail is a handoff that gives the task and nothing about how the reply should look. Ignore the run's own final message here; judge only the text inside the Agent input. Example pass: the handoff ends with "reply with DONE or BLOCKED, then the files you changed." Example fail: the handoff says only "add the --json flag in src/cli/args.py."
