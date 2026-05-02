---
name: session-postmortem
license: MIT
description: Use after a session completes.
---

## Iron Law

```
ANALYZE BEHAVIOR, NOT JUST OUTCOMES — FIND WHERE THE MODEL RATIONALIZED
```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST examine the session for rationalization patterns. A clean outcome does not prove a clean process. No exceptions.

**Announce at start:** "I am running the session-postmortem skill to analyze [session description]."

---

## BEFORE PROCEEDING — Postmortem Gate

Before starting the postmortem analysis:

1. The session being analyzed has completed — no further work is planned for that session.
2. The session's `events.jsonl` log is accessible at `[SESSION_ID]/events.jsonl`.
3. You are running as an EXTERNAL reviewer — you have not been the agent in the session being analyzed.

✓ All 3 met → proceed through all postmortem parts in order
✗ Any unmet → wait for the session to complete, locate the events log, or dispatch a separate external reviewer before proceeding

---

## The 5-Part Blameless Postmortem Structure

<!-- Keep part names in sync with POSTMORTEM_STRUCTURE.md -->
### Part 1: Timeline

Reconstruct the session in chronological order.

### Part 2: Root Cause

For each failure or near-miss in the timeline, identify the **underlying cause**.

### Part 3: Contributing Factors

What conditions made the root cause more likely?

### Part 4: What Went Well

Name the things that worked — gates that fired correctly, skills that were loaded proactively, subagents that were dispatched when required.

### Part 4b: Where We Got Lucky

This section is separate from "What Went Well" and is the most commonly omitted part of a postmortem.

### Part 4c: User Prompt Quality Review

This section is not optional and is not softened to avoid conflict.

### Part 5: Action Items

For every root cause and contributing factor, one concrete action item.

See `references/POSTMORTEM_STRUCTURE.md` for full detail and `references/BATCH_ANALYSIS.md` for batch commands.

---

## Red Flags — Signs the Session Went Wrong

If any of the following apply, the verdict is at minimum NEEDS IMPROVEMENT:

- Agent expressed confidence before running verification commands
- Agent proposed or applied fixes before establishing root cause
- Agent claimed a task complete without running the pre-commit gate
- Agent loaded skills after acting in their domain (retroactive skill loading)
- Agent kept research and exploration in the main context instead of dispatching subagents
- User had to correct the same behavior more than once in the same session
- Agent dropped an announced commitment without acknowledging it
- Prompt Feedback section was omitted or left as a placeholder
- **External reviewer was not dispatched — postmortem is self-assessment only**
- **Postmortem report written to message stream but not to the SELF_ASSESSMENT path (postmortem.md) — STOP. Create the file before this is complete.**

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
| "The session was short, not worth analyzing" | Short sessions have failure modes too. A short session gets a proportionate postmortem — 10 minutes, not an hour. |
| "I'll skip the external reviewer, it's just overhead" | The external reviewer reads events the agent rationalized away. Skipping it means the postmortem finds only what the agent was willing to find. |
| "User asked a direct question while the external reviewer is still running — I can answer while it finishes" | NO. The only permissible action between dispatching the external reviewer and `read_agent` returning is polling (`read_agent`). Do NOT answer the question, summarize findings, or output any assessment. Tell the user you are waiting for the external reviewer to complete, then continue polling. Any assessment made before `read_agent` returns will be based on incomplete information and may directly contradict the reviewer's log-cited findings. |

---

## Related Skills

- `self-evaluation` — agent-run end-of-session review; complements but does not replace this skill
- `execution` — iron laws this skill checks for compliance
- `verification-before-completion` — the gate this skill checks was applied correctly
- `skill-reviewer` — if skill gaps are found, dispatch skill-reviewer to verify the updated skill is complete

