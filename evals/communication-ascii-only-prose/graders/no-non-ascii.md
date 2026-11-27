---
type: regex
pattern: '[^\x09\x0A\x0D\x20-\x7E]'
match: not_contains
target: last_message
---

Behavior: the final message holds only ASCII characters: tab, newline, carriage return and the printable range space to tilde. Any other character, such as a Unicode arrow, em dash, en dash, math operator or check mark, fails. The scaffold files are ASCII only and the prompt asks for no quotation of external text, so the verbatim-quotation exception of the rule never applies and every character of the reply must be ASCII (arrows and dashes in ASCII form, for example -> and --). The pattern is written with \x escapes so the grader file itself stays ASCII. Limitation: it assumes the harness regex engine reads \x escapes inside a character class and tests the message as text; the engine source was not read.
