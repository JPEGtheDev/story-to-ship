---
type: tool_used
tool: Write
input_match: '^(?=.*"file_path":"[^"]*/tests/)(?=.*Fake\w*Clock)(?!.*SystemClock)'
min: 0
max: 0
---

Behavior: the run writes a test file under a `tests/` path that names the fake clock class and does not name `SystemClock`. That is a test for the fake alone, not the shared contract suite the rule requires, so any such write fails the run. A write that names both classes passes. The check is a substring match on the Write input, so no judge is needed. It does not flag a fake-only test written through Edit or Bash, and it does not flag a fake named differently from `Fake...Clock`.
