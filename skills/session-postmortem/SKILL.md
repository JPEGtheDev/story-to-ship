---
name: session-postmortem
license: MIT
description: Use when a completed session needs behavioral retrospective analysis.
---


## Iron Law

```
ANALYZE BEHAVIOR, NOT JUST OUTCOMES -- FIND WHERE THE MODEL RATIONALIZED
YOU MUST examine the session for rationalization patterns. A clean outcome does not prove a clean process. No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the session-postmortem skill to analyze [session description]."

---

## BEFORE PROCEEDING

Before starting the postmortem analysis:

1. The session being analyzed has completed -- no further work is planned for that session.
2. The session's `events.jsonl` log is accessible at the path provided by the user or session context.
3. **If you are the DISPATCHING agent (primary self-assessment role):** You have NOT been the agent in the session being analyzed, OR you are running as the self-assessment author following the Independence Gate in `references/POSTMORTEM_STRUCTURE.md`. Dispatch a `postmortem-reviewer` subagent as the external reviewer.
   **If you are the EXTERNAL reviewer subagent:** You have not been the agent in the session being analyzed and you have no session memory. Read `events.jsonl` cold.
4. Before writing the self-assessment, read `checkpoints/index.md` to determine the full session scope. Context compaction does not shorten the session. A self-assessment that covers only the final task of a 9-hour session is incomplete.

[+] All 4 met -> proceed through all postmortem parts in order
[-] Any unmet -> STOP. Wait for the session to complete, locate the events log, dispatch a separate external reviewer, or read `checkpoints/index.md` before proceeding.

---

## The 5-Part Blameless Postmortem Structure

Full structure and templates: `references/POSTMORTEM_STRUCTURE.md`. Full batch commands: `references/BATCH_ANALYSIS.md`.

Parts in order: Timeline -> Root Cause -> Contributing Factors -> What Went Well -> Action Items.

**Part 4b (Where We Got Lucky) is the most commonly omitted part -- it is not optional.**
**Part 4c (User Prompt Quality Review) is not optional and is not softened to avoid conflict.**

---

## Red Flags -- STOP

If any of the following apply, the verdict is at minimum NEEDS IMPROVEMENT:

- Agent expressed confidence before running verification commands -- STOP. Find the verification that was skipped. Document in Root Cause.
- Agent proposed or applied fixes before establishing root cause -- STOP. Identify what root cause analysis was missing. Document in Root Cause.
- Agent claimed a task complete without running the pre-commit gate -- STOP. Identify which gate was skipped. Add to Action Items.
- Agent loaded skills after acting in their domain (retroactive skill loading) -- STOP. Document which skill was loaded late and what decision it should have gated. Add to Action Items.
- Agent kept research and exploration in the main context instead of dispatching subagents -- STOP. Document the context cost. Add to Action Items.
- User had to correct the same behavior more than once in the same session -- STOP. This is SYSTEMIC ISSUE. Identify the rationalization pattern. Add a rationalization table row to the relevant skill.
- Agent dropped an announced commitment without acknowledging it -- STOP. Document the commitment and the drop. Add to Timeline and Root Cause.
- Prompt Feedback section was omitted or left as a placeholder -- STOP. Complete Part 4c before marking the postmortem done.
- **External reviewer was not dispatched -- STOP. Postmortem is incomplete. Dispatch `postmortem-reviewer` subagent now.**
- **Postmortem report written to message stream but not to disk at `docs/postmortem/YYYY-MM-DD-[SESSION_SHORT_ID].md` -- STOP. Create the file before this is complete.**

Three or more of the above = SYSTEMIC ISSUE. Relevant skills need immediate rationalization table updates.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "It was mostly fine, no need for a postmortem" | "Mostly fine" hides the one failure that will recur. Systematic review is required. |
| "It was a one-off mistake, not a pattern" | Check the full session before concluding that. One-off mistakes look different from patterns only after you check. |
| "The outcome was good, so the process must have been right" | Good outcome from bad process = lucky, not reliable. The blameless principle exists to find the lucky path. |
| "The user didn't complain" | Some failures are silent. The agent may have produced a plausible wrong answer the user accepted. Postmortem finds those. |
| "Self-evaluation already covered this" | Self-eval is by the agent. Postmortem is external. Different perspective, different blind spots. Both are necessary. |
| "The session was short, not worth analyzing" | Short sessions have failure modes too. A short session gets a proportionate postmortem -- 10 minutes, not an hour. |
| "I'll skip the external reviewer, it's just overhead" | The external reviewer reads events the agent rationalized away. Skipping it means the postmortem finds only what the agent was willing to find. |
| "User asked a direct question while the external reviewer is still running -- I can answer while it finishes" | NO. The only permissible action between dispatching the external reviewer and `read_agent` returning is polling (`read_agent`). Do NOT answer the question, summarize findings, or output any assessment. Tell the user you are waiting for the external reviewer to complete, then continue polling. Any assessment made before `read_agent` returns will be based on incomplete information and may directly contradict the reviewer's log-cited findings. |

---

## Related Skills

- `self-evaluation` -- agent-run end-of-session review; complements but does not replace this skill
- `execution` -- iron laws this skill checks for compliance
- `verification-before-completion` -- the gate this skill checks was applied correctly
- `writing-skills` -- if skill gaps are found, use the skill-reviewer agent to verify the updated skill is complete

