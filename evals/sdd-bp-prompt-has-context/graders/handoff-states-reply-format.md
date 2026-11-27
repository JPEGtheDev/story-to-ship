---
type: llm
focus: trace
---

Judge the Agent tool input in the trace. Assumed trace form: compact JSON, so each Agent call is one object whose input field (the prompt text) holds the handoff; judge only that text. Ignore the run's own final message here.

The wanted behavior: the text handed to the helper states the form its reply must take, such as a status word, a fixed set of fields, a single line, or a list of named items to report back. A pass is a handoff that tells the helper how to report: for example it asks for a status line, a list of changed files, or a DONE or BLOCKED word. A fail is a handoff that gives the task and nothing about how the reply should look. Example pass: the handoff ends with "reply with DONE or BLOCKED, then the files you changed." Example fail: the handoff says only "add the --json flag in src/cli/args.py."

A run with no Agent call at all fails. No handoff was made, so nothing in the trace states a reply form, and the run does not show the wanted behavior. The run's final message does not rescue it.
