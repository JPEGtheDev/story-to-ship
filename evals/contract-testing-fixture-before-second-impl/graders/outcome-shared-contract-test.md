---
type: tool_used
tool: Write
input_match: '^(?=[\s\S]*"file_path":"[^"]*/tests/)(?=[\s\S]*"content":"[\s\S]*MemoryStore)(?=[\s\S]*"content":"[\s\S]*(?:FileStore\(|IMPLEMENTATIONS|\w*(?:Contract|Mixin)\w*\s*[,)]))'
min: 1
---

Behavior: the run writes a file under a `tests/` path whose content names `MemoryStore` and also carries a shared-suite mark: a `FileStore(` construction, the name `IMPLEMENTATIONS`, or a Contract or Mixin base class in a class's base list (for example `class MemoryStoreTest(StoreContract, unittest.TestCase)`). A bare word such as `FileStore` in a docstring or `subTest` alone is not a mark. Both `MemoryStore` and a mark must sit in the same Write, so a separate contract mixin that does not name `MemoryStore` does not pass on its own. Any such file passes, whether it is a test class that runs the shared suite against both stores or one that mixes in a shared contract. The check is a substring match on the Write input, so no judge is needed. Limits: the check reads only Write calls. An Edit that turns `tests/test_file_store.py` into a suite over both stores is a compliant route that this grader does not count, so a run that takes that route scores FAIL here. The check does not confirm that the file is run, that the mark is used correctly, or that the suite exists before the second implementation: the call order is not checked, although the case name says "before second impl".
