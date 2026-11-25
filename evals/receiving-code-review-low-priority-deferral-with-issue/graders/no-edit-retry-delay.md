---
type: tool_used
tool: Edit
input_match: 'src/export\.py'
min: 0
max: 0
---

Behavior: the run makes no Edit call whose input names src/export.py, so the retry-delay comment, which is outside the purpose of the PR, is deferred and not fixed inside it. The header row is already in the PR, so the only change left to make in that file is the out-of-scope one. The check counts Edit calls on that path, so no judge is needed.

Limitation of a zero-count check: a run that does nothing also passes it, and a change made through Write or Bash is not covered. It sits beside `creates-tracking-issue` and `defers-with-issue-reference`, which require the deferral itself.
