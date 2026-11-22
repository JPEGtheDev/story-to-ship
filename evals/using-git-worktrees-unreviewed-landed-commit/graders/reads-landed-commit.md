---
type: tool_used
tool: Bash
input_match: '\bgit\b(?:\s+-\S+(?:\s+\S+)?)*?\s+show(?![-\w])(?![^;&|\n]*\s--(?:stat|name-only|numstat|shortstat|name-status)\b)(?!\s+(?:-\S+\s+)*[^\s-]\S*:)'
min: 1
---

Behavior: the run reads a commit with `git show`, with or without global options before it (`git -C <path> show`, `git --no-pager show`, `git -c k=v show`). `git show-ref` and `git show-branch` do not count. A `git show` with `--stat`, `--name-only`, `--numstat`, `--shortstat` or `--name-status` in the same command segment (up to `;`, `&`, `|` or a newline) prints no patch and is not matched. A `<ref>:<path>` first argument (`git show HEAD:plan.md`) reads a file, not the commit, and is not matched. The check is a command form, so no judge is needed. Limits: this grader checks that a read ran, not that it ran before the revert; the paired grader review-before-revert checks the order. A `<ref>:<path>` argument after a commit ref (`git show HEAD HEAD:plan.md`), and a quoted path with a space after `-C` (`git -C "/a b" show`), are not handled.
