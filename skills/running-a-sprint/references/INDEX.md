---
title: "running-a-sprint References Index"
description: "Index of reference files for the running-a-sprint skill -- the hand-back and runner-event routing table with the required hand-back lines, the hand-back size contract and the resume texts, and the sprint scorecard with its predictions, measures table and counting commands, subagent-transcript audit, the per-tier usage close-out step, and per-runner scorecard row, and the coordinator rehearsal procedure with its fixture, arms, counting and result-reading rules, and the owner questions page with its card fields, layout, ledger fields, failure handling and worked example, and the Close-out step 7 reconcile of other open sprint PRs against a merged change with its Reconcile text hand-off, queueing and replacement-runner rules."
domain: skills
subdomain: running-a-sprint
tags: [skills, running-a-sprint, references, index]
related:
  - "../SKILL.md"
---

# running-a-sprint References Index

These files back the Launch, Watch loop and Close-out sections of `../SKILL.md` (`RECONCILE.md` backs Close-out step 7), and `REHEARSAL.md` backs the check to repeat when the story-coordinator template they depend on changes.

---

## Reference Files

| File | Covers |
|------|--------|
| `HANDBACK_ROUTING.md` | Routing table mapping each runner hand-back kind (owner question, PR ready, blocked, cap reached, interim) and each runner event (rate-limit kill, child result while the runner is live, premature turn-end, missing required line, owner-reported merge, owner-reserved item reported as decided) to how the launcher recognizes it, its response and its prohibitions; the required lines in a hand-back; the hand-back size contract (cap, order, Detail line, over-cap handling); the three resume texts (validate-first, child-result, missing-line) |
| `RECONCILE.md` | Close-out step 7, the reconcile of other open sprint PRs against a merged change: the file-overlap test, the Reconcile text hand-off, the ledger states and queueing rules for a runner that is working, held or killed, the replacement-runner rules, and the Reconcile: line check |
| `SCORECARD.md` | The six predictions to record before launch; the measures table with the shell counting commands and how to read each figure; how to audit a subagent transcript with the first-action script on a sidechain-cleared copy; the close-out step that runs the per-tier usage script; the per-runner scorecard row to copy into the sprint ledger |
| `OWNER_QUESTIONS.md` | The owner questions page: the one rolling read-only page the launcher writes from runner hand-backs, the question kinds that get a card, the card fields (number, story or topic, question, options, recommendation, status, plus the launch-card counts and overlap), the context section, the layout and question numbering, the chat line, the sprint ledger fields, failure handling for a missing, failed or stale page, page comments, and a worked example |
| `REHEARSAL.md` | The procedure for rehearsing the story-coordinator template as a coordinator under test: the purpose, the fixture to rebuild (it is not shipped), the GREEN and RED arms, how to run and count, how to read the result, and the limits |

---

## Related

- [SKILL.md](../SKILL.md) -- enforcement gate that drives this skill

The routing table must match the story-coordinator agent template, which defines the hand-back kinds and lines the runners send.
