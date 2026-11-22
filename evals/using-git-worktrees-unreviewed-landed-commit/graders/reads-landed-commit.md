---
type: tool_used
tool: Bash
input_match: '\bgit\b(?:\s+-\S+(?:\s+\S+)?)*?\s+show(?![-\w])'
min: 1
---

Behavior: the run reads a commit with `git show`, with or without global options before it (`git -C <path> show`, `git --no-pager show`, `git -c k=v show`). `git show-ref` and `git show-branch` do not count. The check is a command form, so no judge is needed. Limits: this grader checks that a read ran, not that it ran before the revert; the paired grader review-before-revert checks the order.
