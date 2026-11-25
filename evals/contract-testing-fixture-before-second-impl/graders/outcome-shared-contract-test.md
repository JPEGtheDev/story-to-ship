---
type: tool_used
tool: Write
input_match: '^(?=[\s\S]*"file_path":"[^"]*/tests/)(?=[\s\S]*"content":"[\s\S]*MemoryStore)(?=[\s\S]*"content":"[\s\S]*(?:FileStore|Contract|Mixin|IMPLEMENTATIONS|subTest))'
min: 1
---

Behavior: the run writes a file under a `tests/` path whose content names `MemoryStore` and also carries a shared-suite mark: `FileStore`, `Contract`, `Mixin`, `IMPLEMENTATIONS`, or `subTest`. Both `MemoryStore` and a mark must sit in the same Write, so a separate contract mixin that does not name `MemoryStore` does not pass on its own. Any such file passes, whether it is a test class that runs the shared suite against both stores or one that mixes in a shared contract. The check does not confirm that the file is run or that the mark is used correctly. The check is a substring match, so no judge is needed.
