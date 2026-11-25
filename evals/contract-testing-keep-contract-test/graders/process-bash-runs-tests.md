---
type: tool_used
tool: Bash
input_match: '(pytest|unittest)'
min: 1
---

Behavior: the run runs a test suite (pytest or unittest) at least once through Bash, the step that would surface a broken invariant after the cut. The check is a substring match on the Bash command text. It does not check that the tests passed, that the command named the contract test, or what the output said.
