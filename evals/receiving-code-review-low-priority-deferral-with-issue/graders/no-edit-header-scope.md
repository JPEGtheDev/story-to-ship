---
type: tool_used
tool: Edit
input_match: 'export'
min: 0
max: 0
---

Behavior: the run makes no Edit call on any path that contains `export`, so the comment, which is outside the purpose of the PR, is deferred and not fixed inside it. The check is a command form, so no judge is needed.

Limitation of a zero-count check: a run that does nothing also passes it, and a change made through Write or Bash is not covered. It sits beside `creates-tracking-issue` and `defers-with-issue-reference`, which require the deferral itself.
