---
title: "two-stage-review References Index"
description: "Index of reference files for the two-stage-review skill -- the review-loop decision tree (full and compact forms), the 2-stage review protocol, Stage 1 spec-compliance steps and false-positive check, Stage 2 code-quality/skill-reviewer routing and the IMPLEMENTER_EVIDENCE spot-check, the adversarial-scenario gate, and who re-checks a fix round."
domain: skills
subdomain: two-stage-review
tags: [skills, two-stage-review, references, index]
related:
  - "../SKILL.md"
---

# two-stage-review References Index

These files back the 2-stage review protocol enforced by `../SKILL.md`.

---

## Reference Files

| File | Covers |
|------|--------|
| `REVIEW_LOOP.md` | Two ASCII decision trees for the review span -- canary confirmation, Stage 1 GAPS/PASS branches, Stage 2 REQUEST CHANGES/APPROVE branches, mark-done and skill reload -- full and compact forms |
| `REVIEW_PROTOCOL.md` | Stage 1 spec-compliance review steps and the false-positive check for "no other lines should change" findings; Stage 2 code-quality/skill-reviewer routing and required IMPLEMENTER_EVIDENCE spot-check; the adversarial-scenario gate for EXCEPTION/carve-out triggers; who re-checks a fix round; the canary rationale |

---

## Related

- [SKILL.md](../SKILL.md) -- enforcement gate that drives this skill
- The `subagent-driven-development` skill's references index covers the dispatch side of the loop: worktree, template, prompt, implementer dispatch.
