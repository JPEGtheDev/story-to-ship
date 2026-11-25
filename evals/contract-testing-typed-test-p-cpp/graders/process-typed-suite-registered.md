---
type: tool_used
tool: Write
input_match: '^(?=[\s\S]*"file_path":"[^"]*/tests/)(?=[\s\S]*REGISTER_TYPED_TEST_SUITE_P\()'
min: 1
---

Behavior: the run writes a file whose file_path contains `/tests/` and whose content calls REGISTER_TYPED_TEST_SUITE_P, the registration step that the typed-test suite needs before it is instantiated over the shapes. The check is a regex match on the Write input, so no judge is needed.

Weak proxy: no build runs in this environment (gtest is absent), so the check cannot see whether the suite was compiled or run. It sees only that a write under tests/ registers a typed suite. It does not check that the registration names the suite that was defined, does not check the registration against the instantiation, and does not check that the file was ever built. The tests/ check matches `/tests/` anywhere in file_path, not only as a prefix, so a registration in a header under tests/ passes even when its instantiation is elsewhere.

Known gaps: the deprecated REGISTER_TYPED_TEST_CASE_P( is not matched, so a run that uses it fails this check even when the suite is right. A file_path with no directory before tests/ (for example tests/shape_test.cpp) is not matched.
