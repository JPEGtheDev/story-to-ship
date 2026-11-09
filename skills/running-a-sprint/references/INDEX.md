---
title: "running-a-sprint References Index"
description: "Index of reference files for the running-a-sprint skill -- the hand-back and runner-event routing table with the required hand-back lines, the hand-back size contract and the resume texts, and the hand-back check script handback-check.sh with its check lines, its inline and moved checks, and its exit codes, the pilot hold with its pilot line states and pilot hand-back checks, and the sprint scorecard with its predictions, measures table and counting commands, subagent-transcript audit, the per-tier usage close-out step, and per-runner scorecard row, and the coordinator rehearsal procedure with its fixture, arms, counting and result-reading rules, and the owner questions page with its Ready to merge section, card fields, layout, ledger fields, failure handling and worked example, the Editing the page section with the page editor script page-edit.sh, its operations and exit codes, the Working and Needs you status lines and the data-pr markers, the close-out check and steps scripts with their options, output lines and exit codes, and the Close-out step 7 reconcile of the PR next to merge against a merged change with its Reconcile text hand-off, queueing and replacement-runner rules."
domain: skills
subdomain: running-a-sprint
tags: [skills, running-a-sprint, references, index]
related:
  - "../SKILL.md"
---

# running-a-sprint References Index

These files back the Capacity, Launch and Watch loop sections of `../SKILL.md` and the close-out steps in `../../sprint-close-out/SKILL.md` (`PILOT.md` backs Capacity and Launch, `RECONCILE.md` backs Close-out step 7), and `REHEARSAL.md` backs the check to repeat when the story-coordinator template they depend on changes.

---

## Reference Files

| File | Covers |
|------|--------|
| `HANDBACK_ROUTING.md` | Routing table mapping each runner hand-back kind (owner question, PR ready, blocked, cap reached, interim) and each runner event (rate-limit kill, child result while the runner is live, premature turn-end, missing required line, owner-reported merge, owner-reserved item reported as decided) to how the launcher recognizes it, its response and its prohibitions; the required lines in a hand-back; the hand-back size contract (cap, order, Detail line, over-cap handling); the six resume texts (validate-first, child-result, missing-line, draft, reconcile, fresh-runner); the hand-back check script `handback-check.sh`, its options, the check lines it prints (including the NOTE, inline and moved lines), and its exit codes |
| `PILOT.md` | The pilot hold: the held, failed, passed and released states of the pilot line, the table of pilot line changes by hand-back and event, the pilot's hand-back checks, the owner rulings that end the hold and release the other stories, and the Context and Forces pair of the pilot runner |
| `RECONCILE.md` | Close-out step 7, the reconcile of the PR next to merge against a merged change: the next-to-merge rule and the resolved-hunk review (the reconcile reviews only the resolved conflict hunks on the conflicting files and the changed files of its fix rounds, plus CI; a clean rebase with no conflict and no fix round needs green CI only, with no reviewer), the Reconcile text hand-off, the ledger states and queueing rules for a runner that is working, held or killed, the replacement-runner rules, and the Reconcile: line check |
| `CLOSE_OUT.md` | The close-out scripts: closeout-check.sh and closeout-steps.sh, their options, the check lines and step lines they print, their exit codes, the refusal and failure paths, and the close-out steps that stay manual |
| `SCORECARD.md` | The six predictions to record before launch; the measures table with the shell counting commands and how to read each figure; how to audit a subagent transcript with the first-action script on a sidechain-cleared copy; the close-out step that runs the per-tier usage script; the per-runner scorecard row to copy into the sprint ledger |
| `OWNER_QUESTIONS.md` | The owner questions page: the one rolling page the launcher writes from runner hand-backs, which the owner reads and answers by chat or page comment but never edits; the Ready to merge section of statement entries in the recommended merge order (entry, verification line, optional checks, owner action, stale, waiting and removal rules); the question kinds that get a card, the card fields (number, story or topic, question, options, recommendation, status, plus the launch-card counts and each story's dependency), the pilot check card (fields, release pointer to PILOT.md, removal), the context section, the layout and question numbering with restarts, the chat line, the sprint ledger fields, failure handling for a missing, failed or stale page, owner comments, and a worked example; the Editing the page section with the page editor script `page-edit.sh`, its five operations, its exit codes, and the Working and Needs you status lines and the data-pr markers |
| `owner-questions-template.html` | The starting HTML layout for the owner questions page: one style block and the sections header, Ready to merge, Open questions, Waiting on runners, not you, and Context, with one example entry, card and context section, and a {{NAME}} placeholder for every variable value |
| `REHEARSAL.md` | The procedure for rehearsing the story-coordinator template as a coordinator under test: the purpose, the fixture to rebuild (it is not shipped), the GREEN and RED arms, how to run and count, how to read the result, and the limits |
| `MOVED_RATIONALE.md` | Context and Forces pairs moved out of SKILL.md from the Intake, Capacity, Launch, Watch loop, and Close-out sections. The Launch question owner text section (an operative rule, not a pair) moved out of SKILL.md Capacity. Passages moved word for word out of SKILL.md sit under headings that start with "Moved from SKILL.md:", four topics: launcher role, worktree, waiting stories, and reconcile state; all four are operative rules moved word for word, not rationale. The related skills passage, under "Moved from SKILL.md: related skills", and the reference descriptions passage, under "Moved from SKILL.md: reference descriptions", are navigation, not rules. The rationale heading, "Moved from SKILL.md: rationale", holds rationale clauses only. |

---

## Related

- [SKILL.md](../SKILL.md) -- enforcement gate that drives this skill

The routing table must match the story-coordinator agent template, which defines the hand-back kinds and lines the runners send.
