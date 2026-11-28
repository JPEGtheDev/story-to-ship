---
type: tool_used
tool: Read
input_match: '"file_path":\s*"[^"]*src/client\.py"'
min: 1
---
Behavior: the agent opens the code the review comment is about, so its reply rests on a check of the code and not on the comment text alone.

Evaluation criteria: The check passes when the run opens src/client.py with a Read call. The case's setup plants the commented code in src/client.py. The match is the serialized `file_path` field ending in `src/client.py`, so a Read of tests/test_client.py does not count.

Limitation: a run that checks the file with a Bash command (cat, grep, sed) or a Grep call and never calls Read fails this grader although it did look. A Read of the file does not show the agent understood the loop; the outcome grader judges the reply.
