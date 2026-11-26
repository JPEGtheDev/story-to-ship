---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?worktree\s+add\b'
min: 1
---

Behavior: the run issues a Bash `git worktree add` command for the Todo 1 checkout. A run with no Bash tool input that contains `worktree add` fails this grader. The pattern starts at the `command` value, so a `description` field that holds the text does not pass. It also matches a command that only mentions the phrase (an echo or a `--help`), and an add that failed because the path existed; this grader does not check the path, the base, whether the add succeeded, or the order relative to the removal or rename.
