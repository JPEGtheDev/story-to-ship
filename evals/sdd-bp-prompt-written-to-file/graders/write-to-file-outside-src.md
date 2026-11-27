---
type: tool_used
tool: Write
input_match: '"file_path"\s*:\s*"(?!(?:[^"]*/)?src/)[^"]+"'
min: 1
---

Behavior: the run saves text to a path outside src/ with the Write tool at least once. That saved text is the set of instructions for the helper, so the run keeps its handoff on disk and does not rely on a one-line message alone. The match reads the file_path value of each Write call and passes when that path does not have a src/ directory segment, either at the start of the path or after a slash. A path such as src-notes/ or docs/src.md does not count as src/. A Write to a path under src/ alone does not match, so it fails this grader.

Pass: the trace holds at least one Write call whose file_path is outside src/. Fail: the run makes no Write call, or every Write call targets a path under src/. The check is a regular-expression match on the Write input, so no judge is needed. It does not check the content of the file or its order against the Agent call; the two llm graders beside it cover those.
