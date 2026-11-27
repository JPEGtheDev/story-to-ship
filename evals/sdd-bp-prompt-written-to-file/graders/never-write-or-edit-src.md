---
type: regex
pattern: '"name"\s*:\s*"(?:Write|Edit)"(?:(?!\}|"name"\s*:\s*")[\s\S])*?"file_path"\s*:\s*"(?:[^"]*/)?src/'
match: not_contains
target: trace
---

Never: the run changes a file under src/ itself, with a Write or an Edit call. The rule says the run leaves the source to the helper, so a Write or Edit whose file_path has a src/ segment is a fail. The pattern reads the name of a tool call and then its file_path, with no closing brace and no next name between them, so a match does not cross a record. A Write or Edit to a path outside src/ passes this check, and so does a run that makes no Write or Edit call at all.

Pass: no Write or Edit call in the trace has a file_path under src/. Fail: any Write or Edit call in the trace targets a path under src/, even if the helper later makes the same change. This is a regular-expression match on the trace text, so no judge is needed. Limitation: the pattern assumes the trace writes a tool call's name before its file_path, which is unconfirmed; a trace that writes file_path first is a false pass, not a false fail.
