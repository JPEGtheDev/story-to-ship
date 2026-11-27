---
type: tool_used
tool: Bash
input_match: '"command"\s*:\s*"(?=(?:[^"\\]|\\.)*?grep)(?!(?:[^"\\]|\\.)*?(?:plan\.md|src/))(?:[^"\\]|\\.)*?(?:\[?[Ii]\]?ssue|ISSUE)'
min: 1
---

Pass: the session holds at least one Bash call whose command (the "command" field of the tool input, not the description) runs grep, names the word issue in any common form (issue, Issue, [Ii]ssue, ISSUE, with or without -i), and does not point at plan.md or at anything under src/. The pattern may use single quotes, double quotes, no quotes, or escaped double quotes inside the command. The written instructions file can have any name the run chose, so the grader does not require a file name. Pass examples: "grep -nE '\\b[Ii]ssues?[ ]+#?[0-9]+\\b' brief.md", "grep -nE \"[Ii]ssue[ ]+#?[0-9]+\" todo1-brief.md", "grep -n -i issue /tmp/run/sdd/brief.txt", "grep -c Issue instructions.md". Fail: no Bash call runs grep with the word issue in its command; a description field that says "grep" or "issue" does not count; or the only grep with issue targets plan.md or src/ (for example "grep -n issue plan.md", "cat plan.md | grep -n issue", or "grep -rn issue src/"). The match is on the tool input, so it does not show that the search ran after the Write; the process grader covers the order. Limitation: the match is a regex over the command text, so a search written as a non-grep tool does not count.
