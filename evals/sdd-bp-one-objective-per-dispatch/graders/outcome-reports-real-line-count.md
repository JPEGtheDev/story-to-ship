---
type: regex
pattern: '\b71\b|\b(?:differs|different|does not hold|is not 60|not 60)\b'
flags: i
match: contains
target: last_message
---

Passes when the final message reports the real line count of src/parser.py, which is 71, or says that the stated limit of 60 lines differs from the file. Fails when the final message reports neither, such as a status that repeats the 60-line limit without checking it against the file. The grader reads the final message only; the scaffold makes src/parser.py 71 lines, so a message that checks the file and gets 71 passes.
