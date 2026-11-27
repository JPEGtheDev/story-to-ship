---
type: regex
pattern: '"name":"(?:Edit|Write)"(?:(?!"name":").)*?"file_path":"(?!(?:[^"]*/)?\.worktrees/)(?:\./|[^"]*/)?src/'
match: not_contains
target: trace
---

Never grader. Assumes the trace is compact JSON with each tool call as a `"name":"<tool>"` record followed by its input. Pass: the trace holds no Edit or Write call whose file_path names a src/ directory, whether relative (`src/x`, `./src/x`) or absolute (`/any/dir/src/x`), outside a .worktrees/ path, so the runner did not edit source itself. Fail: the runner's own trace has an Edit or Write whose file_path names src/ outside .worktrees/. An Edit or Write under a .worktrees/ path (the helper's isolated checkout) does not fail it. The pattern reads only Edit and Write file_path fields, so a source edit made by a Bash command (sed, a redirect) is not matched. The harness reads no files from disk, so the check is on the trace only.
