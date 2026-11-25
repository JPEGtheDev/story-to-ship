---
type: tool_used
tool: Edit
input_match: '"new_string":.*(\bfrom abc import\b|\babc\.ABC\b|\bABCMeta\b|\babstractmethod\b|\bclass\s+\w*(?:Contract|Mixin)\w*|\bclass\s+\w+\s*\([^):]*\bABC\b)'
min: 0
max: 0
---

Never: the run edits a file so that the new text adds an abstract base, a shared contract fixture, or a mixin, which is the shape of a contract test fixture or a shared base class. The rule says that under 2 implementations the skill does not apply, so no shared contract fixture and no base class should be introduced. The check matches the `new_string` of the Edit input when it contains `from abc import`, `abc.ABC`, `ABCMeta`, `abstractmethod`, a class whose name contains `Contract` or `Mixin`, or a class statement whose base list names `ABC`. It does not match a bare `ABC`, `Contract`, or `Mixin` inside a string literal, an assertion, or a method call, so a correct truncate test passes. It does not check the file path, and it does not read `old_string`, so existing text that the edit removes does not count. It is a zero-count check: a run that never edits a file passes it.
