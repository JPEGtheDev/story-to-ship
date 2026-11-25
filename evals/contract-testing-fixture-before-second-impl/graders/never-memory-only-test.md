---
type: tool_used
tool: Write
input_match: '^(?=[\s\S]*"file_path":"[^"]*/tests/)(?=[\s\S]*MemoryStore)(?![\s\S]*(?:FileStore|Contract|Mixin|IMPLEMENTATIONS|subTest))'
min: 0
max: 0
---

Red flag: the run writes a file under a `tests/` path that names `MemoryStore` and carries none of the shared-suite marks (`FileStore`, `Contract`, `Mixin`, `IMPLEMENTATIONS`, `subTest`). That is a single-implementation test, the shape the rule forbids before a second implementation ships. The check fails the run when any such Write is issued. A test file that names a mark anywhere in its content is not flagged. A run that writes no test file also passes this check, so it is read together with the positive outcome grader. The check is a substring match, so no judge is needed.
