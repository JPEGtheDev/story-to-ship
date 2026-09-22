# session-bootstrap Rationale -- Reference

Why the rules in `../SKILL.md` exist. Enforcement lives in SKILL.md; this file holds the
reasoning behind it.

---

## Why Invoke Before Acting (Iron Law)

Skills contain rules that change what you do. Loading a skill AFTER acting defeats the
purpose: the action was taken without the rules that govern it.

---

## Why Skill Refresh Is Mandatory

Stale skill context is worse than no skill. Skills evolve. Context windows truncate.
Skills loaded early in a session may no longer be active when you need them.

---

## Why honesty and communication Are Peers

`honesty` and `communication` are not managed by `session-bootstrap`. They are co-equal
peer skills: `session-bootstrap` loads the skills a task's domain requires, but it does
not own these two, so it cannot load them on a task's behalf. That is exactly why they
need their own explicit invocation every session, immediately after `session-bootstrap`
returns, rather than being folded into the On Start task-type table in `../SKILL.md`.

---

## Why Check `git status` Before New Work

Ghost commits from prior agents are a recurring risk. An uncommitted change with no
active work in progress means a prior agent or a manual edit left state behind; starting
new work on top of it contaminates the diff.

---

## Why Hook Fixes Need an Observed Firing

Hook script content is executed fresh on every invocation, and hook registration in
settings files hot-reloads mid-session -- neither requires a restart. That is exactly
why the edit landing is not evidence the hook fired: because the fix takes effect
immediately, "committed" and "confirmed working" collapse into the same moment in an
agent's mental model, but the fix taking effect only means it CAN fire on the next
invocation, not that it DID. An observed firing this session -- injected hook context or
a fresh log line from the hook -- is the only evidence that closes that gap.

---

## Why the Self-Evaluation Block Is Unconditional

Reporting the block with zeroes when there is nothing to report ensures the behavior is
habitual, not conditional. A conditional habit is skipped exactly when it matters.
