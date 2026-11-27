---
type: tool_used
tool: Bash
input_match: "grep(?![^\"]*(?:plan\\.md|src/))[^\"]*(?:\\[Ii\\]ssue|[Ii]ssue|ISSUE)"
min: 1
---

Pass: the session holds at least one Bash call whose command runs grep, names the word issue in any common form (issue, Issue, [Ii]ssue, ISSUE, with or without -i), and does not point grep at plan.md or at anything under src/. The written instructions file can have any name the run chose, so the grader does not require a file name; it only excludes the plan and the source tree. Pass examples: "grep -nE '\\b[Ii]ssues?[ ]+#?[0-9]+\\b' brief.md", "grep -n -i issue /tmp/run/sdd/brief.txt", "grep -c Issue instructions.md". Fail: no Bash call runs grep with the word issue, for example when the run never searches its instructions for tracker references; or the only grep with issue targets plan.md or src/ (for example "grep -n issue plan.md" or "grep -rn issue src/"). The match is on the tool input, so it does not show that the search ran after the Write; the process grader covers the order. Limitation: the match is a regex over the command text, so a search written as a non-grep tool does not count.
