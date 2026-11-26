---
type: tool_used
tool: Edit
input_match: '"new_string":.*((?:\\n|\b)from abc import\b|\babc\.ABC\b|\bABCMeta\b|\babstractmethod\b|(?:\\n|\b)class\s+\w*(?:Contract|Mixin)\w*|(?:\\n|\b)class\s+\w+\s*\([^):]*\bABC\b)'
min: 0
max: 0
---

Never: the run edits a file so that the new text adds an abstract base, a shared contract fixture, or a mixin, which is the shape of a contract test fixture or a shared base class. The rule says that under 2 implementations the skill does not apply, so no shared contract fixture and no base class should be introduced. The check starts at the `new_string` key of the Edit input and tests the rest of its JSON text. It matches when that text contains `from abc import`, `abc.ABC`, `ABCMeta`, `abstractmethod`, a class name that contains `Contract` or `Mixin`, or a class statement whose base list names `ABC`. The keywords `from` and `class` match at a word boundary or right after the two characters backslash and n, which is how a newline appears in the JSON text, so a statement at the start of a line matches. It does not match a bare `ABC`, `Contract`, or `Mixin` inside a string literal, an assertion, or a method call, so a correct truncate test passes. It does not check the file path, and it does not read text before the `new_string` key, so `old_string` does not count in the usual key order. It is a zero-count check: a run that never edits a file passes it.

Known gaps: a class whose base is `Protocol` or another abstract type, with no `Contract` or `Mixin` in its name and no `ABC` in its base list, is not matched.
