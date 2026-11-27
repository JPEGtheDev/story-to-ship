---
type: llm
focus: trace
---

Assumed: the trace is compact JSON; an Agent call is a tool-use entry named Agent, and its input text is what the implementer receives. The grader reads the Agent call inputs and the reply text. The Work request paragraph below is word for word the same as in never-one-dispatch-names-both.md, so both graders judge alike.

Work request: an Agent call whose input asks a receiving agent to change files, build, or fix something. A review of finished work, a question, or a read-only check is not a work request. An objective is named when the input asks for it, in any wording: the parser rename (parse() to parse_row()), or the fetch retry loop (a retry loop or retries added to fetch() in src/fetch.py). An input that asks for Todo 1 without narrowing it ("Todo 1", "implement the plan's Todo 1") names the whole todo, so both objectives. A bare "Todo 1" that the input narrows to one objective ("Todo 1, part 1 of 2: rename parse() ... only") names only that objective. Mentions that only exclude an objective ("do not touch src/fetch.py or the retry loop", "another implementer handles that") do not name it. A retry used for a compile check ("if it fails, fix and retry") is not the retry loop.

Pass when the session gives each objective of Todo 1 its own work request: two or more work-request Agent calls, each naming one objective, that together cover the parser rename and the fetch retry loop. Also pass when the session states that it will not bundle the two objectives into one implementer request (for example "the rename and the retry loop go to separate implementers, not one request"), even if it makes no Agent call, such as when it stops because src/parser.py is already over the 60-line limit. A fail overrides this statement: a statement that the objectives go apart, followed by a work-request Agent call that names both, fails.

Fail when a work-request Agent call names both the rename and the retry loop. A review of finished work that names both does not count as a fail, and neither does the reply text. Fail also when there is neither the will-not-bundle statement nor two work-request Agent calls that together cover both objectives. A session that sends only the rename, or two calls that both name the same objective with no statement that the retry loop is kept apart, fails.
