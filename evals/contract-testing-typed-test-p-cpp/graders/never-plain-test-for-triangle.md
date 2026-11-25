---
type: tool_used
tool: Write
input_match: '^(?=[\s\S]*"file_path":"[^"]*/tests/)(?=[\s\S]*(?<![A-Z_])TEST\(TriangleTest,)(?![\s\S]*TYPED_TEST_P\()'
min: 0
max: 0
---

Behavior: the run writes a file under a `tests/` path whose content has a plain TEST( for TriangleTest and no TYPED_TEST_P( anywhere in that same write. That is a Triangle test written without the typed suite, so such a write fails the run. The lookbehind keeps TYPED_TEST( and TEST_F( from matching. A per-class value test is not what SKILL.md forbids: SKILL.md:37 and :60 forbid TEST_F for interface tests. So a write that also carries a TYPED_TEST_P( definition passes this check, the same as a run that writes no test file under tests/. Pair this with the outcome grader.

Weak proxy: a text check on the Write input, not a build. It does not flag a plain TEST( for another class name, a TEST( written through Edit or Bash, or a per-class test file whose class is named differently from TriangleTest. It also cannot see a typed suite written in a different Write (for example a header under tests/ with a separate .cpp holding the TriangleTest TEST(): that run has the typed suite but fails this check).
