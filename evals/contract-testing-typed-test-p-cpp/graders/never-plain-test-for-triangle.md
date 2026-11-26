---
type: tool_used
tool: Write
input_match: '^(?=[\s\S]*"file_path":"[^"]*/tests/)(?=[\s\S]*(?<![A-Z_])TEST(?:_F)?\(\s*TriangleTest,)(?![\s\S]*TYPED_TEST_P\()'
min: 0
max: 0
---

Behavior: the run writes a file whose file_path contains `/tests/` and whose content has a `TEST(` or a `TEST_F(` for TriangleTest, and no `TYPED_TEST_P(` anywhere in that same write. SKILL.md:37 and :60 name TEST_F as the form to avoid for an interface test, and a plain TEST( for TriangleTest with no typed suite is the same miss, so either form fails the run. Blanks after the open parenthesis are allowed (`TEST( TriangleTest,` is flagged). `TYPED_TEST(` is not flagged, because the lookbehind rejects an uppercase letter or underscore before `TEST`. A write that also carries a `TYPED_TEST_P(` definition passes this check, the same as a run that writes no test file under tests/. Pair this with the outcome grader.

Weak proxy: a text check on the Write input, not a build. It does not flag a plain TEST( for another class name, a TEST( written through Edit or Bash, or a per-class test file whose class is named differently from TriangleTest.

Known gaps: the check reads one Write at a time, so a typed suite in a header under tests/ with a TEST(TriangleTest, ...) in a separate .cpp is flagged even though the run has the typed suite. A file_path with no directory before tests/ (for example tests/triangle_test.cpp) is not matched. A space between TEST and the open parenthesis (`TEST (`) and a line break inside the call are not matched; the scorer sees a line break as the two characters backslash and n.
