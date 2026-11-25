---
type: tool_used
tool: Write
input_match: '"content":.*(ABC|abstractmethod|Contract|Mixin)'
min: 0
max: 0
---

Never: the run writes a file whose content uses an abstract base, `abstractmethod`, a `Contract` name, or a `Mixin`, which is the shape of a contract test fixture or a shared base class. The rule says that under 2 implementations the skill does not apply, so no shared contract fixture and no base class should appear. The check matches the content of the Write input only, not the file path. It is a zero-count check: a run that never writes a file passes it.
