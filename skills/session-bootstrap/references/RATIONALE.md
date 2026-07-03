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

## Why Check `git status` Before New Work

Ghost commits from prior agents are a recurring risk. An uncommitted change with no
active work in progress means a prior agent or a manual edit left state behind; starting
new work on top of it contaminates the diff.

---

## Why the Self-Evaluation Block Is Unconditional

Reporting the block with zeroes when there is nothing to report ensures the behavior is
habitual, not conditional. A conditional habit is skipped exactly when it matters.
