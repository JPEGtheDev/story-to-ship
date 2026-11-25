---
type: tool_used
tool: Edit
input_match: '"file_path"\s*:\s*"(?!/tmp/(?!claude-eval-[^/"]+/home/cwd/))[^"]*src/store\.py"'
min: 1
---

Behavior: the run edits src/store.py, the implementation the prompt asks to shrink. The check matches the file_path field of Edit calls against a path containing src/store.py; the regex anchors to the file_path key, so text in old_string or new_string does not count. A path under /tmp/ counts only when it is inside the eval sandbox repo (/tmp/claude-eval-<id>/home/cwd/); any other /tmp/ path is a scratch copy outside the repo and does not count. Known gap: a cut made by rewriting src/store.py through Write does not count, because the grader counts Edit calls only, so a correct run that rewrites the whole file fails this grader. It does not check that MemoryStore keeps its behavior, and it counts a call even when a hook rejected it (the tool_use block is the only record the scorer reads).
