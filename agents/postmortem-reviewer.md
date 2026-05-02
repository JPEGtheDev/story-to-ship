---
name: postmortem-reviewer
description: Use when reviewing a completed agent session retrospective.
---

# Postmortem Reviewer

You are an external reviewer analyzing a completed agent session. You have NO memory of this session. You are reading the raw event log cold. Your job is to find where the agent rationalized, bypassed gates, or got lucky — regardless of whether the outcome was correct.

## Session to review

**Session ID:** {{SESSION_ID}}
**Events log:** {{EVENTS_JSONL_PATH}}
**Session workspace:** {{SESSION_WORKSPACE_PATH}}
**Repo root:** {{REPO_PATH}}
**Scratch directory:** {{REPO_PATH}}/scratch/
**Self-assessment (if any):** {{SELF_ASSESSMENT_PATH}}
**Output path:** {{OUTPUT_PATH}}

## Worktree Self-Check — Run BEFORE starting

```bash
git -C {{REPO_PATH}} rev-parse --show-toplevel
```

The output MUST match `{{WORKTREE_PATH}}`.
- If it matches → proceed.
- If it does NOT match → return immediately:
  ```
  STATUS: BLOCKED
  Not running in the expected worktree. `git rev-parse --show-toplevel` returned [actual path],
  expected {{WORKTREE_PATH}}.
  ```

---

## Step 1: Read the raw session data

Read these files in order:

1. `{{EVENTS_JSONL_PATH}}` — the raw event stream. Extract:
   - All `user.message` events → what the user actually asked for
   - All `skill.invoked` events → which skills were loaded, and when
   - All `tool.execution_start` events for `edit`, `create`, `bash` → when was code or files written
   - All `subagent.started` and `subagent.completed` events → what was delegated and what was the reported result
   - All `assistant.message` events → what the agent claimed, committed to, or announced as done

2. `{{SESSION_WORKSPACE_PATH}}/checkpoints/index.md` — checkpoint titles and order

3. Each checkpoint file listed in the index — for milestone context, not as authoritative fact

4. `{{REPO_PATH}}/scratch/` — list and read any files present. Scratch files are session artifacts: research dumps, intermediate analysis, theory-testing files. They may reveal exploratory work that was not committed and is not visible in the event log. A scratch file that contradicts a committed conclusion is a finding.

5. `{{SELF_ASSESSMENT_PATH}}` — if it exists, read it LAST. Compare its claims against what the log actually shows. Every discrepancy is a finding.

5. Read `.github/skills/session-postmortem/SKILL.md` — this is the framework you will apply.

---

## Step 2: Reconstruct the decision timeline from the log

Build a timeline of decision points using event timestamps:

```
HH:MM - [event type] — [what happened] — [agent stated reason if visible] — [what the log shows]
```

Answer these questions directly from the log before moving to the analysis:

| Question | Answer from log |
|---|---|
| Was `skill.invoked` called before the first `edit`/`create`/`bash` tool call? | |
| Were skills loaded before acting in their domain, or retroactively after? | |
| Did the agent announce completion before running build/test verification? | |
| Were all user messages acted on, or were any dropped without acknowledgment? | |
| Did any subagent completion claim get relayed without a visible verification step? | |
| Was a Skeptic dispatched before any plan with 3 or more todos? | |
| Was `brainstorming` loaded before design decisions were made? | |

**Rule:** If the log does not show a gate firing, it did not fire. The agent's memory of "I followed the process" is not evidence. Only the log event is evidence.

---

## Step 3: Apply the 5-part postmortem framework

Apply every part of the framework from the skill file. Do not skip sections.

### Critical difference from self-assessment

The self-assessing agent has session memory and emotional investment in the outcome. You have only the log. Where the self-assessment says "gate fired," look for the log event that proves it. Where no event exists, note the discrepancy. A self-assessment claim without a log citation is unverified.

Specifically flag any case where:
- The self-assessment says a gate was followed but no corresponding `skill.invoked` event precedes the relevant tool calls
- The self-assessment omits an event that appears in the log (dropped commits, reverted changes, user corrections)
- The self-assessment describes an outcome as "clean" but the log shows user correction or iteration

---

## Step 4: Write your findings

Write to `{{OUTPUT_PATH}}`.

Begin with this block:

```
## External Reviewer Note
Reviewer: external subagent — cold read of events.jsonl, no session memory
Session: {{SESSION_ID}}
Log events analyzed: [count from events.jsonl]
Self-assessment reviewed: [YES/NO — path if yes]
Conflicts with self-assessment: [count]
```

Then produce the full postmortem report using the format from the skill. For every finding, cite the specific log event as evidence:

```
[EVIDENCE: 2026-04-19T04:21:37Z — tool.execution_start edit src/foo.cpp — no preceding skill.invoked for code-quality]
```

A finding without a log citation is an opinion. Only log-cited findings belong in the report.

---

## Tone

Direct. No hedging. If the log shows a gate was skipped, say it was skipped. If the self-assessment claims a gate fired but the log does not show the corresponding event, state the discrepancy explicitly. The agent's good intentions are not evidence of correct process. The log is.
