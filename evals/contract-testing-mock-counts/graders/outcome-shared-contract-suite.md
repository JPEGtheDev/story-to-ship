---
type: tool_used
tool: Write
input_match: '^(?=.*"file_path":"[^"]*/tests/)(?=.*Fake\w*Clock)(?=.*(?:SystemClock|\(\s*\w*(?:Contract|Mixin)\w*\s*[,)]|IMPLEMENTATIONS))'
min: 1
---

Behavior: the run writes a file under a `tests/` path whose content names the fake clock class and also either names `SystemClock` or carries a shared-suite mark, so one shared contract suite covers the real clock and the fake. The fake class is matched as `Fake` followed by word characters and `Clock` (for example `FakeClock`). The shared-suite marks are a base class named Contract or Mixin inside the class's parentheses (for example `class FakeClockContractTest(ClockContract, unittest.TestCase)`, the contract-mixin layout, where the real clock's test file subclasses the same base) or the name `IMPLEMENTATIONS`. The check is a substring match on the Write input, so no judge is needed. It does not check that the suite passes, that the fake is in `src/fake_clock.py`, or that the file is a real contract test: a comment that names `SystemClock` next to a fake-only class still matches, and a plain word Contract or Mixin in a comment or a class name does not count as a mark. A base file under `tests/` that names neither the fake nor `SystemClock` does not match on its own; the subclass file that names the fake and a mark does.
