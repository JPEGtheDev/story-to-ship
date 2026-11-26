---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?:[^"\\]|\\.)*?--show-toplevel'
min: 1
---

Behavior: the run asks git for its top-level root (the top-level check). `--show-toplevel` is the git option that returns that root, so any form of the query that reads the root matches. A run that never queries the root fails. This grader checks only that a root query ran; a bare query in the main checkout also matches. Whether the query targets the checkout the run is about to dispatch is not checked here. The regex grader toplevel-before-dispatch checks only that `.worktrees/` and `--show-toplevel` appear in one command before the first Agent call, so it does not prove the target either. The check is a command form, and a judge is not needed to read it. The pattern starts at the `command` value, so a description alone does not pass.
