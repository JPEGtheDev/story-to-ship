---
type: tool_used
tool: Write
input_match: '^(?=.*"file_path":"[^"]*/tests/)(?=.*SystemClock)(?=.*Fake\w*Clock)'
min: 1
---

Behavior: the run writes a file under a `tests/` path whose content names both `SystemClock` and the fake clock class, so one shared contract suite covers the real clock and the fake. The fake class is matched as `Fake` followed by word characters and `Clock` (for example `FakeClock`). The check is a substring match on the Write input, so no judge is needed. It does not check that the suite passes, that the fake is in `src/fake_clock.py`, or that the file is a real contract test rather than a comment that names both classes.
