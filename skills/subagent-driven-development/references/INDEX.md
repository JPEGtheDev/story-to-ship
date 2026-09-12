---
title: "subagent-driven-development References Index"
description: "Index of reference files for the subagent-driven-development skill -- the Subagent-Driven Development (SDD) loop decision tree, the 2-stage review protocol, model tier selection and the general-purpose rule, worktree setup and self-check, rationale, and the agent templates index."
domain: skills
subdomain: subagent-driven-development
tags: [skills, subagent-driven-development, references, index]
related:
  - "../SKILL.md"
---

# subagent-driven-development References Index

These files back the Subagent-Driven Development (SDD) loop enforced by `../SKILL.md`.

---

## Reference Files

| File | Covers |
|------|--------|
| `AGENT_TEMPLATES.md` | Table of all 17 agent templates in `agents/` with Use-when match text and Model column (all sonnet today); dispatch rule when no row matches; CI checks each row against the template frontmatter |
| `MODEL_SELECTION.md` | Model preference priority order, task-type tier table, Economy/Standard/Premium tier definitions and the content-touching work floor, named agent/ceremony tier assignments, Premium justification rule, tier-cost comparison rule, and the general-purpose dispatch rule (state closest template considered, tier reasoning, pass `model` explicitly) |
| `REVIEW_PROTOCOL.md` | Stage 1 spec-compliance review steps and the false-positive check for "no other lines should change" findings; Stage 2 code-quality/skill-reviewer routing and required IMPLEMENTER_EVIDENCE spot-check; the adversarial-scenario gate for EXCEPTION/carve-out triggers; who re-checks a fix round |
| `SDD_LOOP.md` | Full decision tree from picking up a todo through implementer status codes (NEEDS_CONTEXT, BLOCKED, PARTIAL, DONE_WITH_CONCERNS, DONE), canary confirmation, Stage 1/Stage 2 review branches, rationale for the three gates, and a condensed quick-reference flowchart |
| `SDD_RATIONALE.md` | Why subagents are mandatory, the empirical evidence mandate with acceptable/not-acceptable evidence lists, delegation quality rules, an anti-patterns table, and the canary rationale |
| `WORKTREE_SELF_CHECK.md` | Canonical Worktree Self-Check block text -- Variant A (read-only templates) and Variant B (write templates with branch-isolation step) for agent templates to copy verbatim |
| `WORKTREE_SETUP.md` | Pre-dispatch worktree checks (gitignore, create, verify path, branch isolation for write-side agents) and why read-only agents also need worktrees |

---

## Related

- [SKILL.md](../SKILL.md) -- enforcement gate that drives this skill
