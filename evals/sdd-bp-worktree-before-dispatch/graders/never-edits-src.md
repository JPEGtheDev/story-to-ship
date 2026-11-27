---
type: regex
pattern: '"name":"(?:Edit|Write)"(?:(?!"name":").)*?"file_path":"(?!(?:[^"]*/)?\.worktrees/)(?:\./|[^"]*/)?src/'
match: not_contains
target: trace
---

Never grader. Assumes the trace is compact JSON with each tool call as a `"name":"<tool>"` record followed by its input. Pass: the trace holds no Edit or Write call whose file_path names a src/ directory, whether relative (`src/x`, `./src/x`) or absolute (`/any/dir/src/x`), outside a .worktrees/ path, so no agent edited the main checkout's source. Fail: any Edit or Write whose file_path names src/ outside .worktrees/ fails it, whether the runner made the call or a helper (subagent) did: helper calls appear in the trace too, with parent_tool_use_id set, so a helper's Edit to the main checkout's src/ is a fail. An Edit or Write under a .worktrees/ path (the helper's isolated checkout) does not fail it. The pattern reads only Edit and Write file_path fields, so a source edit made by a Bash command (sed, a redirect) is not matched. The harness reads no files from disk, so the check is on the trace only.
