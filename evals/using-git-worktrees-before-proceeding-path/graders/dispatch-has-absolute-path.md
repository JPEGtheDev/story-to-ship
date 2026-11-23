---
type: tool_used
tool: Agent
input_match: '(?:(?<![^\s"`''(:*=])|(?<=\\n)|(?<=\\t))/(?!\.worktrees/)[^\s"`\\]*\.worktrees/csv-export-todo1'
min: 1
---

Behavior: the implementer dispatch prompt names the worktree by its absolute path (a path that starts at the root and ends in `.worktrees/...`). A relative `.worktrees/` mention alone does not match, because the rule asks for the absolute path so the subagent does not resolve it against its own working directory. The leading `/` must follow the start of the text, whitespace, a double quote, a backtick, `(`, `:`, a single quote, `*` or `=` (for example `cd '/abs/...'`, `**/abs/...**` or `WT=/abs/...`), or a JSON-escaped newline or tab (the two characters `\n` or `\t`). That `/` may not be followed directly by `.worktrees/`, so a glob such as `**/.worktrees/...` does not match. Between that `/` and `.worktrees/` the path may hold any character except whitespace, a double quote, a backtick or a backslash, so an escaped newline or tab inside the path does not match in either the raw or the serialized form. So `repo/.worktrees/`, `./.worktrees/`, `~/...`, `${REPO}/...` and `<repo-root>/...` do not match as absolute. The check is a path form, so no judge is needed. Limitation: the pattern does not check the prefix against the real repo root, so a made-up absolute path such as `/repo/.worktrees/csv-export-todo1` passes; a worktree path that contains a space does not match.
