---
type: tool_used
tool: Bash
input_match: 'worktree\s+add\b'
min: 1
---

Behavior: the run creates a git worktree through a Bash `git worktree add` command. A run with no `git worktree add` command fails this grader. The pattern also matches a command that only mentions the phrase (an echo or a `--help`), and a failed or `../` add; this grader does not check the path, the base or the order. The check is a command-form match, so no judge is needed.
