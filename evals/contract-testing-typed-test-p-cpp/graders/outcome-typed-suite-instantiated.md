---
type: tool_used
tool: Write
input_match: '^(?=[\s\S]*"file_path":"[^"]*/tests/)(?=[\s\S]*TYPED_TEST_P\()(?=[\s\S]*INSTANTIATE_TYPED_TEST_SUITE_P\()'
min: 1
---

Behavior: the run writes a file under a `tests/` path whose content defines a typed test with TYPED_TEST_P( and instantiates a typed suite with INSTANTIATE_TYPED_TEST_SUITE_P(, both in the same write. That is the shape the rule expects: one suite parameterized over the shapes, not one TEST per class. The check is a regex match on the Write input, so no judge is needed.

Weak proxy: this is a text check, not a build. It does not show the file compiles, that the suite runs, or that the instantiation lists the shapes. A write that contains both macro calls passes even if the types or the test bodies are wrong. It also does not check that the typed definition and the instantiation refer to the same suite name.

Known gaps: a suite split across Writes is not matched. For example, TYPED_TEST_P( in tests/shape_contract.h and INSTANTIATE_TYPED_TEST_SUITE_P( in tests/triangle_test.cpp leave neither write with both macros. INSTANTIATE_TYPED_TEST_CASE_P( (the deprecated instantiation macro) is not matched, so a run that uses it fails this check even when the suite is right. TYPED_TEST_CASE_P( is not required, so a run that declares its suite with it, defines tests with TYPED_TEST_P(, and instantiates with INSTANTIATE_TYPED_TEST_SUITE_P( passes. A file_path with no directory before tests/ (for example tests/triangle_test.cpp) is not matched.
