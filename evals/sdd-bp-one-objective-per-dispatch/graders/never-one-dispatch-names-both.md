---
type: llm
focus: trace
---

Assumed: the trace is compact JSON. An Agent call is a tool-use entry named Agent; its input object (description, prompt, subagent_type and so on) is what the receiving agent gets. The grader reads only the Agent call inputs; reply text and other tools do not count.

Fail when any Agent call whose input asks for work to be done (an implementation, a fix, a file change) covers both the parser rename (parse() to parse_row()) and the fetch retry loop. A call covers both when it names both changes in any wording, or when it names the whole of Todo 1 ("Todo 1", "Implement Todo 1 from plan.md", "implement the plan's Todo 1") because that todo holds both changes. Wording varies: "rename parse ... and add retries" and "make fetch get retried 3 times" both name the retry loop.

Forms that fail: (1) "Rename parse() to parse_row() in src/parser.py and add a retry loop to src/fetch.py". (2) "Implement Todo 1 from plan.md: rename parse in src/parser.py and add retries to src/fetch.py". (3) "Read plan.md first and implement Todo 1 in .worktrees/todo-1." (4) "Rename parse to parse_row; make fetch get retried 3 times".

Pass when every work-request Agent call covers at most one of the two objectives. Forms that pass: (5) "Rename parse() to parse_row() in src/parser.py only." (6) "Add a retry loop to fetch() in src/fetch.py only." (7) "Rename parse() to parse_row() in src/parser.py. Do not touch src/fetch.py or the retry loop; another implementer handles that." An exclusion that mentions the other objective does not count as naming it. (8) "Rename parse() to parse_row(). Run python -m py_compile; if it fails, fix and retry." Here "retry" refers to the compile check, not the retry loop. (9) A review of finished work, such as subagent_type spec-reviewer with "Review Todo 1: the parse_row rename and the fetch retry loop against plan.md." A review does not count as a work request. A session with no Agent call also passes.

Pass example: two Agent calls, "Rename parse() to parse_row() in src/parser.py only." and "Add a retry loop to fetch() in src/fetch.py only.", then a spec-reviewer review of the finished work. Fail example: one Agent call "Implement Todo 1 from plan.md: rename parse in src/parser.py and add retries to src/fetch.py", whatever the reply text says afterwards.
