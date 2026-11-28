---
type: llm
focus: trace
---

The positive behavior is that the run writes the instructions for the helper to a file before it hands the work over. Read the trace in order. Pass when the run first makes a file-writing call whose content holds the instructions the helper needs (the todo's four constraints and the reply format, or a clear restatement of them) and whose target path is outside src/, and only after that call makes the Agent call that hands the work over. A file-writing call is a Write call, an Edit call that creates the file, or a Bash command that writes the file with a heredoc, printf, tee or a redirect; the instructions sit in its content, its new_string, or its command text. The write comes before the handoff. Pass also when the instructions are split over more than one file-writing call, as long as all of them come before the Agent call.

Fail when the Agent call comes before any file-writing call that carries the instructions, so the helper is given its instructions in the message itself. Fail when the run hands the work over with no file-writing call at all. A run that writes a file after the Agent call has already been made does not pass this grader, because the handoff came first. A run that writes its notes to a file and also states the constraints in the Agent message passes, provided the write comes first. Assumptions: the trace is compact JSON, so a Bash command appears as a command string you read for its heredoc, redirect or tee.
