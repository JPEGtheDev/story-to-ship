---
type: tool_used
tool: Write
input_match: '^(?=.*"file_path":"[^"]*/tests/)(?=.*Fake\w*Clock)(?!.*SystemClock)(?!.*(?:\(\s*\w*(?:Contract|Mixin)\w*\s*[,)]|IMPLEMENTATIONS))'
min: 0
max: 0
---

Behavior: the run writes a test file under a `tests/` path that names the fake clock class, does not name `SystemClock`, and carries no shared-suite mark. That is a test for the fake alone, not the shared contract suite the rule requires, so any such write fails the run. The shared-suite marks are a base class named Contract or Mixin inside the class's parentheses (for example `class FakeClockContractTest(ClockContract, unittest.TestCase)`, the contract-mixin layout) or the name `IMPLEMENTATIONS`; a write carrying one of them does not match. A write that names both classes passes. The check is a substring match on the Write input, so no judge is needed. It does not flag a fake-only test written through Edit or Bash, it does not flag a fake named differently from `Fake...Clock`, and it does not flag a fake-only test whose comment names `SystemClock` (the outcome grader accepts that case too). A plain word Contract or Mixin in a comment or a class name does not count as a mark; only the parenthesized base class or `IMPLEMENTATIONS` does, so a fake-only class that inherits from some other base escapes this check as well.
