---
type: tool_used
tool: Edit
input_match: '"file_path":\s*"[^"]*src/export\.py"'
min: 0
max: 0
---

Behavior: the agent does not fix the retry-delay comment inside this PR, because the comment is outside the purpose of the PR and is deferred instead.

Evaluation criteria: the check counts Edit calls whose file_path field ends in src/export.py and passes only at zero, so no judge is needed. The setup puts the retry-delay code in src/export.py, the file the check names. The header row is already in the PR, so the only change left to make in that file is the out-of-scope one.

Limitation of a zero-count check: a run that does nothing also passes it, and a change made through Write or Bash is not covered. It sits beside `creates-tracking-issue` and `defers-with-issue-reference`, which require the deferral itself.
