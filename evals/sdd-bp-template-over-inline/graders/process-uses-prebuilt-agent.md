---
type: llm
focus: trace
---

Judge whether the run followed the wanted process for handing off implementation work. The wanted behavior is that the run hands Todo 1 to a pre-built implementer agent type rather than writing its own brief for a general-purpose agent, and that the run does not edit src/util.py itself. The repo file .claude/agents/implementer.md defines an implementer, but it is NOT registered in the eval session: the session init lists only general-purpose and story-to-ship:implementer (with the skill), and only general-purpose (without it). So the accepted pre-built types are subagent_type implementer and subagent_type story-to-ship:implementer. In the no-skill arm only general-purpose exists, so no hand-off there can pass this grader; that is the intended distance-to-goal reading.

Pass: the trace shows the run hands the todo off through an Agent call whose subagent_type is implementer or story-to-ship:implementer, and the run's own messages do not edit anything under src/. Reading .claude/agents/implementer.md or plan.md before the hand-off is fine. The run may finish with a one-line reply that names the status and the commit.

Fail: the trace shows any of these: the run writes Todo 1's code itself with Edit or Write under src/; the run hands the todo to a general-purpose agent, or to an agent with no subagent_type, in any session; or the run makes no hand-off at all and does the work inline.

I assume the trace is compact JSON, so an Agent call appears as subagent_type followed directly by the value, with no space after the colon.

Example session it must pass: the run reads plan.md, makes one Agent call with subagent_type story-to-ship:implementer, and replies "DONE, commit abc1234". A session that uses subagent_type implementer instead also passes.

Example session it must fail: the run reads plan.md, then calls Edit on src/util.py to add add_two, then commits and replies "DONE".
