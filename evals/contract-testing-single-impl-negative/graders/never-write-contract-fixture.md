---
type: tool_used
tool: Write
input_match: '"content":.*(\bfrom abc import\b|\babc\.ABC\b|\bABCMeta\b|\babstractmethod\b|\bclass\s+\w*(?:Contract|Mixin)\w*|\bclass\s+\w+\s*\([^):]*\bABC\b)'
min: 0
max: 0
---

Never: the run writes a file whose content adds an abstract base, a shared contract fixture, or a mixin, which is the shape of a contract test fixture or a shared base class. The rule says that under 2 implementations the skill does not apply, so no shared contract fixture and no base class should appear. The check matches the `content` of the Write input when it contains `from abc import`, `abc.ABC`, `ABCMeta`, `abstractmethod`, a class whose name contains `Contract` or `Mixin`, or a class statement whose base list names `ABC`. It does not match a bare `ABC`, `Contract`, or `Mixin` inside a string literal, an assertion, or a method call, so a correct truncate test passes. It does not check the file path. It is a zero-count check: a run that never writes a file passes it.
