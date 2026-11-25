---
type: tool_used
tool: Write
input_match: '^(?=[\s\S]*"file_path":"[^"]*/tests/)(?=[\s\S]*REGISTER_TYPED_TEST_SUITE_P\()'
min: 1
---

Behavior: the run writes a file under a `tests/` path whose content calls REGISTER_TYPED_TEST_SUITE_P, the registration step that the typed-test suite needs before it is instantiated over the shapes. The check is a substring match on the Write input, so no judge is needed.

Weak proxy: no build runs in this environment (gtest is absent), so the check cannot see whether the suite was compiled or run. It sees only that a write under tests/ registers a typed suite. It does not check that the registration names the suite that was defined, does not check the registration against the instantiation, and does not check that the file was ever built. The tests/ check is a path prefix, so a registration in a header under tests/ passes even when its instantiation is elsewhere.
