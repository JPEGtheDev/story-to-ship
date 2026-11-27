---
type: tool_used
tool: Bash
input_match: "grep(?![^\"]*(?:plan\\.md|src/))[^\"]*(?:[xX]7[Ff]|[xX][89][0-9A-Fa-f]|u00[89A-Fa-f]|:ascii:|:print:|P[{]ASCII|[^ -~])"
min: 1
---

Pass: the session holds at least one Bash call whose command runs grep over the written instructions file (any name the run chose; plan.md and src/ are excluded) and whose pattern tests for non-ASCII characters. The grader accepts the forms: a grep -P class on the hex range that ends at 0x7F (for example [^\x00-\x7F], with the backslashes written in any escaped form), a class on the 0x80 to 0xFF range, the POSIX [:ascii:] or [:print:] classes, the Unicode P{ASCII} property, a negated printable range such as [^ -~], or a literal non-ASCII character in the command. Pass examples: "LC_ALL=C grep -nP '[^\\x00-\\x7F]' brief.md", "grep -nP '[^[:print:]]' brief.md". Fail: no Bash call runs grep with a non-ASCII test over the written file, for example when the run only searches for issue references, or when its only grep over the brief has a plain ASCII pattern such as "grep -n issue brief.md". Limitation: the match is a regex over the command text, so a non-ASCII check run through a tool other than grep does not count, and the grader cannot tell whether the search's output was reported; the process grader covers that.
