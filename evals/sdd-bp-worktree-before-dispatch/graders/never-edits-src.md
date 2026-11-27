---
type: regex
pattern: '"name":"(?:Edit|Write)"(?:(?!"name":").)*?"file_path":"(?:\./)?src/'
match: not_contains
target: trace
---

Never grader. Pass: the trace holds no Edit or Write call whose file_path is a relative src/ path, so the runner did not edit source itself. Fail: the runner's own trace has an Edit or Write whose file_path starts with src/. Edits made inside the worktree (paths under .worktrees/) and absolute paths are not matched by this pattern, so they do not fail it.
