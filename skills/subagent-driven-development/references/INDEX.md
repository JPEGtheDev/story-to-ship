---
title: "subagent-driven-development References Index"
description: "Index of reference files for the subagent-driven-development skill -- the Subagent-Driven Development (SDD) loop decision tree, model tier selection and the general-purpose rule, worktree setup and self-check, rationale, and the agent templates index."
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
| `AGENT_TEMPLATES.md` | Table of all 17 agent templates in `agents/` with Use-when match text and Model column (mirrors each template's frontmatter pin); dispatch rule when no row matches; CI checks each row against the template frontmatter |
| `MODEL_SELECTION.md` | Model preference priority order, task-type tier table, Economy/Standard/Premium tier definitions and the content-touching work floor, named agent/ceremony tier assignments, Premium justification rule, tier-cost comparison rule, and the general-purpose dispatch rule (state closest template considered, tier reasoning, pass `model` explicitly), and the Coordinator tier section (the tier of the main agent coordinating a multi-todo plan, the evidence needed to change it, and the record of scored sessions) |
| `SDD_LOOP.md` | Decision tree from picking up a todo through implementer status codes (NEEDS_CONTEXT, BLOCKED, PARTIAL, DONE_WITH_CONCERNS, DONE) to the hand-off into the two-stage-review skill at the DONE arrow, the after-all-todos Ceremony 5 branch, rationale for the three gates, and a condensed quick-reference flowchart |
| `SDD_RATIONALE.md` | Why subagents are mandatory, the empirical evidence mandate with acceptable/not-acceptable evidence lists, delegation quality rules, an anti-patterns table, and the canary rationale |
| `WORKTREE_SELF_CHECK.md` | Canonical Worktree Self-Check block text -- Variant A (read-only templates) and Variant B (write templates with branch-isolation step) for agent templates to copy verbatim |
| `WORKTREE_SETUP.md` | Pointer to the four Create steps of the `using-git-worktrees` skill (the commands are not repeated), the read-only exemption (skip step 4), the `{{WORKTREE_PATH}}` hand-off, and why read-only agents also need worktrees |

---

## Related

- [SKILL.md](../SKILL.md) -- enforcement gate that drives this skill
- The `two-stage-review` skill's references index covers the review side of the loop: status codes, canary, Stage 1, Stage 2, fix-round re-checks.
