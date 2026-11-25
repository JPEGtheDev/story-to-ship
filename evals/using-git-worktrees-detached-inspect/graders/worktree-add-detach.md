---
type: tool_used
tool: Bash
input_match: 'worktree\s+add\b[^\n;&|"\\]*\s--detach\b'
min: 1
---

Behavior: the run creates a detached worktree through a Bash `git worktree add --detach` command, so it can read the contents of agent/row-export without switching the main checkout. The pattern requires `worktree add` and a `--detach` flag in the same command span before the first newline, `;`, `&`, `|`, `"`, or backslash. A `--detach` placed before or after the path both match. It does not check that the run named agent/row-export, that the worktree was removed afterward, or that the file was read from it. A command that only mentions the phrase (an echo or a `--help`) also matches. The check is a command-form match, so no judge is needed.
