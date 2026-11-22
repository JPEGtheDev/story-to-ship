---
type: tool_used
tool: Agent
input_match: '(?:(?<![^\s"`(:])|(?<=\\n)|(?<=\\t))/[^\s"`]*\.worktrees/csv-export-todo1'
min: 1
---

Behavior: the implementer dispatch prompt names the worktree by its absolute path (a path that starts at the root and ends in `.worktrees/...`). A relative `.worktrees/` mention alone does not match, because the rule asks for the absolute path so the subagent does not resolve it against its own working directory. The lookbehind allows only the start of the text, whitespace, a quote, a backtick, `(` or `:` before the leading `/`, so `repo/.worktrees/`, `./.worktrees/`, `~/...`, `${REPO}/...` and `<repo-root>/...` do not match as absolute. The check is a path form, so no judge is needed. The two escaped alternatives `(?<=\\n)|(?<=\\t)` let the match start after a JSON-escaped newline or tab, so a serialized input is matched the same way as a raw one. Limitation: the pattern does not check the prefix against the real repo root, so a made-up absolute path such as `/repo/.worktrees/csv-export-todo1` passes; a worktree path that contains a space does not match.
