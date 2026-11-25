---
type: tool_used
tool: Write
input_match: 'REGISTER_TYPED_TEST_SUITE_P\('
min: 1
---

Behavior: the run writes a file whose content calls REGISTER_TYPED_TEST_SUITE_P, the registration step that the typed-test suite needs before it is instantiated over the shapes. The check is a substring match on the Write input, so no judge is needed.

Weak proxy: no build runs in this environment (gtest is absent), so the check cannot see whether the suite was compiled or run. It sees only that the written text registers a typed suite. It does not check the file path, does not check that the registration names the suite that was defined, and does not check that the file was ever built.
