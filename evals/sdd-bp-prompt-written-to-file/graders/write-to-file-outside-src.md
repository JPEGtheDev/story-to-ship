---
type: regex
pattern: '"name"\s*:\s*"(?:Write|Edit)"(?:(?!\}|"name"\s*:\s*")[\s\S])*?"file_path"\s*:\s*"(?!(?:[^"]*/)?src/)[^"]+"|"name"\s*:\s*"Bash"(?:(?!\}|"name"\s*:\s*")[\s\S])*?"command"\s*:\s*"[^"]*?(?:\s>>?|\btee(?:\s+-a)?)\s*(?!&|/dev/null|(?:[^\s"]*/)?src/)[^\s"]+'
match: contains
target: trace
---

Behavior: the run saves text to a file outside src/, so the instructions for the helper live on disk and the run does not rely on a one-line message alone. A file write counts in three forms: a Write call whose file_path is outside src/; an Edit call whose file_path is outside src/ (an Edit that creates the file); or a Bash command that writes a path outside src/ with a redirect (> or >>), tee, or a heredoc or printf sent into one of those. The Bash branch reads the command string of each Bash call and passes on a redirect or tee whose target is not /dev/null, not a file descriptor (>&), and not under src/. The Write and Edit branches read the file_path value and pass when that path has no src/ directory segment, either at the start of the path or after a slash. A path such as src-notes/ or docs/src.md does not count as src/.

Pass: the trace holds at least one such file write outside src/. Fail: the run makes no file write (no Write or Edit call with a path outside src/, and no Bash redirect or tee into a path outside src/), or every write targets a path under src/. The check is a regular-expression match on the trace text, so no judge is needed. It does not check the content of the file or its order against the Agent call; the two llm graders beside it cover those.

Assumptions and limits: the trace is compact JSON, a tool call's name is written before its input, and a Bash command appears as a command string. The check cannot tell a runner write from a helper write, so a helper's Write outside src/ also passes (the trace may or may not hold helper calls). A space before a > in quoted prose inside a Bash command also passes the Bash branch without a file write; the llm graders on the same case rule on content. A write under src/ made with Bash is not caught here; the never grader covers Write and Edit only.
