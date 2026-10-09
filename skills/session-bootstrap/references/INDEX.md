---
title: "session-bootstrap References Index"
description: "Index of reference files for the session-bootstrap skill -- context, forces, and row definitions for the greenfield dispatch rows in the On Start table."
domain: skills
subdomain: session-bootstrap
tags: [skills, session-bootstrap, references, index]
related:
  - "../SKILL.md"
---

# session-bootstrap References Index

---

## Reference Files

| File | Covers |
|------|--------|
| `SKILL_DISPATCH_TABLE.md` | Context, forces, and row definitions for the greenfield dispatch rows in the "On Start" table; also lists the one row still deferred because its skill is absent, and the greenfield invocation chain. Also tags every row core vs. domain and lists the core skills the per-turn routing block in `hooks/pre-message-gates.md` must name -- `hooks/tests/run-skill-map-drift.sh` enforces that contract mechanically |
| `RATIONALE.md` | Why the SKILL.md rules exist -- invoke-before-acting, skill refresh, why honesty and communication are peers, git status check, why hook fixes need an observed firing, unconditional self-evaluation block |

---

## Related

- [SKILL.md](../SKILL.md) -- "On Start" dispatch table that SKILL_DISPATCH_TABLE.md annotates; see the `greenfield-discovery`, `greenfield-architecture`, and `greenfield-bootstrap` skills for the greenfield dispatch rows
