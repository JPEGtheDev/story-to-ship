---
type: regex
pattern: '"name":\s*"(?:Edit|Write)",\s*"input":\s*\{[^{}]*?"file_path":\s*"[^"]*src/export\.py"'
match: not_contains
target: trace
---

Behavior: the agent does not fix the retry-delay comment inside this PR, because the comment is outside the purpose of the PR and is deferred instead.

Evaluation criteria: the check searches the run's trace for an Edit or a Write tool call whose file_path field in the tool input holds src/export.py, and passes only at zero such calls, so no judge is needed. The setup puts the retry-delay code in src/export.py, the file the check names. The header row is already in the PR, so the only change left to make in that file is the out-of-scope one.

Limitation of a zero-count check: a run that does nothing also passes it, and a change made through a shell command is not covered, nor is a change made through a subagent the agent starts (the Agent tool). A call that the tool refuses or that fails still matches, so it counts as a false fail. It sits beside `creates-tracking-issue` and `defers-with-issue-reference`, which require the deferral itself. The pattern reads the tool name and the file_path field of the tool input, with the file_path field before any brace in that input.
