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
3. Self-evaluation skill run and output written to `self-assessment.md` in the repo root from memory, before reading any session artifacts. The Independence Gate in `references/POSTMORTEM_STRUCTURE.md` requires self-assessment to be written from memory first. The external reviewer reads `self-assessment.md` to find discrepancies between what the agent claimed and what the log shows. A postmortem without a self-assessment is missing the agent's own perspective.
4. Read `checkpoints/index.md` to determine the full session scope (only after self-assessment.md is written). Context compaction does not shorten the session. A self-assessment that covers only the final task of a 9-hour session is incomplete. If `checkpoints/` does not exist, note the absence and determine scope from the compacted context summary and `events.jsonl` instead.
5. **DISPATCHING agent:** Dispatch a `postmortem-reviewer` subagent as external reviewer. For self-assessment authorship rules, follow the Independence Gate in `references/POSTMORTEM_STRUCTURE.md`.
   **EXTERNAL reviewer subagent:** No session memory. Read `events.jsonl` cold.

[+] All 5 met -> proceed through all postmortem parts in order
[-] Any unmet -> STOP. Wait for the session to complete, locate the events log, run self-evaluation and write self-assessment.md from memory first (Independence Gate), then read checkpoints/index.md (or note its absence) to determine scope, then dispatch the external reviewer.

---

## The 5-Part Blameless Postmortem Structure

Full structure and templates: `references/POSTMORTEM_STRUCTURE.md`. Full batch commands: `references/BATCH_ANALYSIS.md`.

Parts in order: Timeline -> Root Cause -> Contributing Factors -> What Went Well -> Action Items.

**Part 4b (Where We Got Lucky) is the most commonly omitted part -- it is not optional.**
**Part 4c (User Prompt Quality Review) is not optional and is not softened to avoid conflict.**

---

## Red Flags -- STOP

If any of the following apply, the verdict is at minimum NEEDS IMPROVEMENT:

- Agent expressed confidence before running verification commands -- STOP. Document skipped verification in Root Cause.
- Agent proposed or applied fixes before establishing root cause -- STOP. Document missing root cause analysis in Root Cause.
- Agent claimed a task complete without running the pre-commit gate -- STOP. Document skipped gate. Add to Action Items.
- Agent loaded skills after acting in their domain (retroactive skill loading) -- STOP. Document which skill was loaded late and which decision it was required to gate. Add to Action Items.
- Agent kept research in main context instead of dispatching subagents -- STOP. Document the context cost. Add to Action Items.
- User corrected the same behavior more than once -- STOP. SYSTEMIC ISSUE. Add a rationalization table row to the relevant skill.
- Agent dropped an announced commitment -- STOP. Document the commitment and the drop in Timeline and Root Cause.
- Prompt Feedback section omitted or left as placeholder -- STOP. Complete Part 4c before marking the postmortem done.
- **External reviewer not dispatched -- STOP. Dispatch `postmortem-reviewer` subagent now.**
- **Postmortem report not written to `sessions/YYYY-MM-DD-[SESSION_SHORT_ID].md` -- STOP. Create the file now.**

Three or more of the above = SYSTEMIC ISSUE. Relevant skills need immediate rationalization table updates.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "It was mostly fine, no need for a postmortem" | "Mostly fine" hides the one failure that will recur. Systematic review is required. |
| "It was a one-off mistake, not a pattern" | Check the full session before concluding that. One-off mistakes look different from patterns only after you check. |
| "The outcome was good, so the process must have been right" | Good outcome from bad process means the failure did not trigger this time. It will. |
| "The user didn't complain" | Some failures are silent. The agent may have produced a plausible wrong answer the user accepted. Postmortem finds those. |
| "Self-evaluation already covered this" | Self-eval is by the agent. Postmortem is external. Different perspective, different blind spots. Both are necessary. |
| "The session was short, not worth analyzing" | Short sessions have failure modes too. A short session gets a proportionate postmortem -- 10 minutes, not an hour. |
| "I'll skip the external reviewer, it's just overhead" | The external reviewer reads events the agent rationalized away. Skipping it means the postmortem finds only what the agent was willing to find. |
| "User asked a direct question while the external reviewer is still running -- I can answer while it finishes" | NO. The only permissible action between dispatching the external reviewer and `read_agent` returning is polling (`read_agent`). Do NOT answer the question, summarize findings, or output any assessment. Tell the user you are waiting for the external reviewer to complete, then continue polling. |

---

## Related Skills

`self-evaluation` (complements, does not replace) | `execution` (iron laws) | `verification-before-completion` (completion gate) | `writing-skills` (skill-reviewer for gaps)

