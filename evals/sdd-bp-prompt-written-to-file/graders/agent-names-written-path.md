---
type: llm
focus: trace
---

The positive behavior is that the message handed to the helper points at the same file the run wrote, so the helper can find its instructions there. Find the call that saved the instructions and note the path it wrote: the file_path of a Write call, the file_path of an Edit call that created the file, or the target of a Bash command that wrote it with a redirect, tee, heredoc or printf. Then read the input of the Agent call that hands the work over. Pass when the Agent input names that same path (the same string, or the same path written as an absolute path that ends in the same relative name). Pass also when the Agent input says where the instructions are and names the file the write call created.

Fail when the Agent input names a different path from the one written, or names no path and repeats the instructions instead. Fail when the Agent input says the instructions are in a file, but the path it names was never written by a file-writing call in this trace. A run that makes no file-writing call has nothing to name, so it fails this grader. Assumptions: the trace is compact JSON, so a Bash command appears as a command string that you read for its redirect or tee target.
