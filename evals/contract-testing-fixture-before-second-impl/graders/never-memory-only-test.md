---
type: tool_used
tool: Write
input_match: '^(?=[\s\S]*"file_path":"[^"]*/tests/)(?=[\s\S]*MemoryStore)(?![\s\S]*(?:FileStore\(|IMPLEMENTATIONS|\w*(?:Contract|Mixin)\w*\s*[,)]))'
min: 0
max: 0
---

Red flag: the run writes a file under a `tests/` path that names `MemoryStore` and carries none of the shared-suite marks (a `FileStore(` construction, the name `IMPLEMENTATIONS`, or a Contract or Mixin base class in a base list). That is a single-implementation test, the shape the rule forbids before a second implementation ships. The check fails the run when any such Write is issued. A test file that carries a mark anywhere in its content is not flagged. A bare word such as `FileStore` in a docstring, or a `subTest` loop alone, does not count as a mark, so a memory-only test that uses either is flagged. The check reads only Write calls: a memory-only test added by Edit is not counted here. A run that writes no test file also passes this check, so it is read together with the positive outcome grader. The check is a substring match, so no judge is needed.
