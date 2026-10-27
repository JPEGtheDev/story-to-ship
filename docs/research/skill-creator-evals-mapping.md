---
title: "claude plugin eval: mapping onto the coordinator rehearsal and two CI text pins"
description: "Maps claude plugin eval onto the story-coordinator rehearsal and two CI text pins, stating what each would replace, add and not cover."
domain: research
subdomain: skill-testing
tags: [research, skill-testing, mapping]
related:
  - "skill-creator-evals-sources.md"
  - "skill-creator-evals-mechanics.md"
  - "claude-plugin-eval.md"
  - "skill-creator-evals.md"
  - "skill-creator-evals-mapping-loop.md"
---

# claude plugin eval mapped onto this repo

Targets: the coordinator rehearsal (`skills/running-a-sprint/references/REHEARSAL.md`) and two pins in `.github/workflows/validate.yml`, checked as fixed strings. The workflow comment (L144) says they prove wording exists, not coordinator behaviour. Loop: [skill-creator-evals-mapping-loop.md](skill-creator-evals-mapping-loop.md). plugin-evals L-numbers: plain-text page in [claude-plugin-eval.md](claude-plugin-eval.md).

| Target | Would replace | Would add | Would not cover |
|---|---|---|---|
| Coordinator rehearsal | Hand-built counting from the transcript (inference: a `tool_used` grader on the Agent tool with `input_match` could count dispatches and background dispatches). Hand-reading of the hand-back. | A bounded local run (`--runs`, `--max-cost-usd`) and a scaffold script for the fixture (plugin-evals L745, L1568). Hand-back checked by `regex`. | The fixture and scaffold are still hand-written. Two runs give no rate. Each run is paid. The judge model is unmeasured: one observed run had the model grader fail 3 of 3 votes while the regex grader passed (claude-plugin-eval.md, Observed). |
| Pin (a): `The dispatcher never reuses or resumes a role child.` (THREE_ROLE_LOOP.md L37; validate.yml L146) | The wording check only. | A behaviour case: `tool_used` on the Agent tool counting re-dispatches to a child (inference: the input field is unverified). | Whether a dispatcher resumes a child on a given run; one stochastic run unless repeated. |
| Pin (b): `A change to any other file is a finding, and the todo returns for a fresh test-writer.` (THREE_ROLE_LOOP.md L47; validate.yml L145) | The wording check only. | A `file_exists` grader could show a stray created file. | An edit to an existing file: `file_exists` sees only files created in the run (plugin-evals L1965). Whether the reviewer flags it. |

## Limits of the `claude plugin eval` mapping
- Cases run in an empty working directory with a temporary home (plugin-evals "How runs are isolated").
- In a baseline arm, a plugin agent is not found (plugin-evals L1926-1930). A case needing `agents/story-coordinator.md` needs `--ablation none` (inference).

## Related
- [skill-creator-evals-sources.md](skill-creator-evals-sources.md) -- primary sources.
- [skill-creator-evals-mechanics.md](skill-creator-evals-mechanics.md) -- skill-creator case fields, grading and calls.
- [claude-plugin-eval.md](claude-plugin-eval.md) -- grader types, flags, observed run.
- [skill-creator-evals-mapping-loop.md](skill-creator-evals-mapping-loop.md) -- same targets, skill-creator loop.
- [skill-creator-evals.md](skill-creator-evals.md) -- main report.
