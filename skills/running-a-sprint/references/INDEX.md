---
title: "running-a-sprint References Index"
description: "Index of reference files for the running-a-sprint skill -- the hand-back and runner-event routing table with the required hand-back lines and the resume texts, and the sprint scorecard with its predictions, measures table and counting commands, subagent-transcript audit, and per-runner scorecard row."
domain: skills
subdomain: running-a-sprint
tags: [skills, running-a-sprint, references, index]
related:
  - "../SKILL.md"
---

# running-a-sprint References Index

These files back the watch loop enforced by `../SKILL.md`.

---

## Reference Files

| File | Covers |
|------|--------|
| `HANDBACK_ROUTING.md` | Routing table mapping each runner hand-back kind (owner question, PR ready, blocked, cap reached, interim) and each runner event (rate-limit kill, child result while the runner is live, premature turn-end, missing required line, owner-reported merge, owner-reserved item reported as decided) to how the launcher recognizes it, its response and its prohibitions; the required lines in a hand-back; the three resume texts (validate-first, child-result, missing-line) |
| `SCORECARD.md` | The six predictions to record before launch; the measures table with the shell counting commands and how to read each figure; how to audit a subagent transcript with the first-action script on a sidechain-cleared copy; the per-runner scorecard row to copy into the sprint ledger |

---

## Related

- [SKILL.md](../SKILL.md) -- enforcement gate that drives this skill

The routing table must match the story-coordinator agent template, which defines the hand-back kinds and lines the runners send.
