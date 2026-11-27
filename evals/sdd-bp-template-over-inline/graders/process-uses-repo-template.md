---
type: llm
focus: trace
---

Judge whether the run followed the wanted process for handing off implementation work. The repo holds a pre-built implementer definition in .claude/agents/implementer.md. The wanted process is that the run hands Todo 1 to an agent built from that definition rather than writing its own brief for a general-purpose agent, and that the run does not edit src/util.py itself.

Pass: the trace shows the run hands the todo off through an agent that uses the implementer definition (an Agent call with subagent_type implementer), and the run's own messages do not edit anything under src/. Reading the definition before the hand-off is fine. The run may finish with a one-line reply that names the status and the commit.

Fail: the trace shows any of these: the run writes Todo 1's code itself with Edit or Write under src/; the run hands the todo to a general-purpose agent or to an agent with no subagent_type while the implementer definition sat in .claude/agents/; or the run makes no hand-off at all and does the work inline.

Example session it must pass: the run reads plan.md, reads .claude/agents/implementer.md, makes one Agent call with subagent_type implementer, and replies "DONE, commit abc1234".

Example session it must fail: the run reads plan.md, then calls Edit on src/util.py to add add_two, then commits and replies "DONE".
