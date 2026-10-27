---
title: "Skill-creator loop: mapping onto the coordinator rehearsal and two CI text pins"
description: "Maps the skill-creator trigger loop, benchmark, grader and comparator onto the coordinator rehearsal and two CI text pins."
domain: research
subdomain: skill-testing
tags: [research, skill-testing, mapping]
related:
  - "skill-creator-evals-mapping.md"
  - "skill-creator-evals-mechanics.md"
  - "skill-creator-evals.md"
---

# Skill-creator loop mapped onto this repo

Targets, as in [the plugin eval mapping](skill-creator-evals-mapping.md): the coordinator rehearsal (`skills/running-a-sprint/references/REHEARSAL.md`) and pins (a) and (b) in `.github/workflows/validate.yml` (L145-146). Each cell gives its source line or is marked inference.

| Target | Would replace | Would add | Would not cover |
|---|---|---|---|
| Coordinator rehearsal | Hand-reading of the hand-back (REHEARSAL.md L56), if a grader assertion with evidence is trusted (grader.md L7, L30; inference). Counts stay with the rehearsal's own counting (REHEARSAL.md L37): grader metrics are model-written (grader.md L136-145; inference). | Benchmark: the shipped template against the rules-removed copy, run as with-skill and baseline subagents (SKILL.md L171; inference). Blind comparator: an unlabeled A/B read of the hand-back (comparator.md L7-9; SKILL.md L325-327; inference). | Needs subagents (SKILL.md L329, L434) and an interactive viewer (SKILL.md L236-251, L265). Dispatch counts still come from the rehearsal. |
| Pin (a): "The dispatcher never reuses or resumes a role child." | Nothing; the wording check stays (validate.yml L146). | Nothing over a script grepping the same wording (inference). A transcript grader could judge a re-dispatch (grader.md L16-30; inference). | Whether a dispatcher resumes a child on a given run. The trigger loop scores only Skill and Read calls (run_eval.py L143-168). One run is one sample (inference). |
| Pin (b): "A change to any other file is a finding, and the todo returns for a fresh test-writer." | Nothing. The pin checks wording only (validate.yml L145). | Nothing over the role-boundary detector CI already runs (validate.yml L871-885; inference that it covers this rule). | Whether a reviewer flags an out-of-scope edit. The trigger loop scores only Skill and Read calls (run_eval.py L143-168). |

## Trigger loop
run_eval.py and run_loop.py test whether a skill description makes Claude trigger the skill: each case is a query with should_trigger (run_eval.py L217, L230), scored on a Skill call or a Read of the skill (run_eval.py L143-168). It replaces and adds nothing to the three targets (inference: none is a description-matching question).

## Limits
- Benchmark and comparator results are inference until a rehearsal runs them.
- The rehearsal fixture is not shipped (REHEARSAL.md L11).

## Related
- [skill-creator-evals-mapping.md](skill-creator-evals-mapping.md) -- plugin eval mapping, same targets.
- [skill-creator-evals-mechanics.md](skill-creator-evals-mechanics.md) -- case fields, grading and calls.
- [skill-creator-evals.md](skill-creator-evals.md) -- main report.
