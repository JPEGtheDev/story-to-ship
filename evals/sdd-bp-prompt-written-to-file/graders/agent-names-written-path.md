---
type: llm
focus: trace
---

The positive behavior is that the message handed to the helper points at the same file the run wrote, so the helper can find its instructions there. Find the Write call that saved the instructions, note its file_path, then read the input of the Agent call that hands the work over. Pass when the Agent input names that same path (the same string, or the same path written as an absolute path that ends in the same relative name). Pass also when the Agent input says where the instructions are, in the same way, and names the file the Write call created.

Fail when the Agent input names a different path from the one written, or names no path and repeats the instructions instead. Fail when the Agent input says the instructions are in a file, but the path it names was never written by a Write call in this trace. A run that makes no Write call has nothing to name, so it fails this grader.
