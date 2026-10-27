---
title: "Skill-creator and plugin eval: mapping onto the coordinator rehearsal and two CI text pins"
description: "Maps the eval toolkits onto the story-coordinator rehearsal and two CI text pins, stating what each would replace, add and not cover."
domain: research
subdomain: skill-testing
tags: [research, skill-testing, mapping]
related:
  - "skill-creator-evals-sources.md"
  - "skill-creator-evals-mechanics.md"
  - "claude-plugin-eval.md"
  - "skill-creator-evals.md"
---

# Eval toolkits mapped onto this repo

Targets: the coordinator rehearsal (`skills/running-a-sprint/references/REHEARSAL.md`) and two pins in `.github/workflows/validate.yml`, checked by fixed-string match (`grep -qF`). The workflow comment (L144) says they prove wording exists, not that a coordinator follows it.

| Target | Would replace | Would add | Would not cover |
|---|---|---|---|
| Coordinator rehearsal | Hand-built counting of dispatches and background dispatches from the transcript (inference: a `tool_used` grader on the Agent tool with `input_match` for the background flag could count these). Hand-reading of the hand-back. | A bounded local run: `--runs`, `--max-cost-usd`, and a scaffold script that builds the fixture (plugin-evals, sandbox passages). Machine-checked hand-back via `regex` over the last message. | The fixture and the scaffold script are still hand-written. Two runs give no rate. Each run is a paid model run. The judge model is unmeasured: one observed run had the model grader fail 3 of 3 votes while the regex grader passed (claude-plugin-eval.md, Observed). |
| Pin (a): `The dispatcher never reuses or resumes a role child.` (THREE_ROLE_LOOP.md L37; validate.yml L146) | The wording check only. | A behaviour case: `tool_used` on the Agent tool counting re-dispatches to an existing child (inference: the exact input field is unverified). | Whether a dispatcher resumes a child on a given run. A passing case is one stochastic run unless repeated. |
| Pin (b): `A change to any other file is a finding, and the todo returns for a fresh test-writer.` (THREE_ROLE_LOOP.md L47; validate.yml L145) | The wording check only. | A `file_exists` grader could show a stray created file. | An edit to an existing file: `file_exists` counts only files created during the run, so a file that Claude only modified is invisible (plugin-evals L1965). Whether the reviewer flags it. |

## Limits of the plugin eval mapping
- Cases run in an empty working directory with a temporary home (plugin-evals "How runs are isolated").
- In a baseline arm, a plugin agent is not found (plugin-evals L1926-1930). A case needing `agents/story-coordinator.md` needs `--ablation none` (inference).

## Related
- [skill-creator-evals-sources.md](skill-creator-evals-sources.md) -- primary sources for the skill-creator claims.
- [skill-creator-evals-mechanics.md](skill-creator-evals-mechanics.md) -- case fields, grading and model call counts for that toolkit.
- [claude-plugin-eval.md](claude-plugin-eval.md) -- grader types, flags and the one observed run.
- [skill-creator-evals.md](skill-creator-evals.md) -- main report and recommendation.
