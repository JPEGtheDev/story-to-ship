---
type: tool_used
tool: Edit
input_match: '"new_string":.*(ABC|abstractmethod|Contract|Mixin)'
min: 0
max: 0
---

Never: the run edits a file so that the new text uses an abstract base, `abstractmethod`, a `Contract` name, or a `Mixin`, which is the shape of a contract test fixture or a shared base class. The rule says that under 2 implementations the skill does not apply, so no shared contract fixture and no base class should be introduced. The check matches only the `new_string` of the Edit input, so existing text that the edit removes does not count. It is a zero-count check: a run that never edits a file passes it.
