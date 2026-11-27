---
type: llm
focus: trace
---

The positive behavior is that the run writes the instructions for the helper to a file before it hands the work over. Read the trace in order. Pass when the run first makes a Write call whose content holds the instructions the helper needs (the todo's four constraints and the reply format, or a clear restatement of them) and whose file_path is outside src/, and only after that Write call makes the Agent call that hands the work over. The write comes before the handoff. Pass also when the instructions are split over more than one Write call, as long as the Write calls all come before the Agent call.

Fail when the Agent call comes before any Write call that carries the instructions, so the helper is given its instructions in the message itself. Fail when the run hands the work over with no Write call at all. A run that writes a file after the Agent call has already been made does not pass this grader, because the handoff came first. A run that writes its notes to a file and also states the constraints in the Agent message passes, provided the Write comes first.
