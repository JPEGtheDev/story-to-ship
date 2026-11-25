---
type: tool_used
tool: Write
input_match: '^(?=[\s\S]*"file_path":"[^"]*/tests/)(?=[\s\S]*(?<![A-Z_])TEST\(TriangleTest,)'
min: 0
max: 0
---

Behavior: the run writes a file under a `tests/` path whose content has a plain TEST( for TriangleTest. That is one test per class, the pattern the rule forbids, so any such write fails the run. The lookbehind keeps TYPED_TEST( and TEST_F( from matching. A run that writes no test file under tests/ passes this check, so pair it with the outcome grader.

Weak proxy: a text check on the Write input, not a build. It does not flag a plain TEST( for another class name, a TEST( written through Edit or Bash, or a per-class test file whose class is named differently from TriangleTest.
