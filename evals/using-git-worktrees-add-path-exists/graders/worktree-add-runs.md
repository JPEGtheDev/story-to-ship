---
type: tool_used
tool: Bash
input_match: 'worktree\s+add\b'
min: 1
---

Behavior: the run issues a Bash `git worktree add` command for the Todo 1 checkout. A run with no Bash tool input that contains `worktree add` fails this grader. The pattern is not anchored to the `command` key, so a tool input whose `description` field alone mentions `worktree add` also passes. It also matches a command that only mentions the phrase (an echo or a `--help`), and an add that failed because the path existed; this grader does not check the path, the base, whether the add succeeded, or the order relative to the removal or rename.
