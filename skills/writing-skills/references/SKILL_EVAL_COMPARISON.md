---
title: "Old-Versus-New Eval Comparison"
description: "Procedure for comparing a shortened or reworded skill against its prior text with claude plugin eval, and for recording the skill's on-invoke token cost before and after."
domain: skills
subdomain: writing-skills
tags: [skills, writing-skills, references, eval, token-cost]
related:
  - "../SKILL.md"
  - "SIZE_AND_COMPRESSION.md"
---

# Old-Versus-New Eval Comparison

Use this procedure before shipping an edit that shortens or rewords a skill. It measures the change; it does not shorten anything.

## a. When It Applies

1. Run this procedure before shipping any edit that shortens or rewords a skill's SKILL.md or references/ text. Step d.1 compares the commit before the edit with the edited tree, so the comparison runs after the edit and before shipping.
2. Ship the changed skill only when, for every case and on every tier that ran it, the count of passing runs for the new version is at least the old version's count. A passing run is an entry of the case's `arms.with` list whose `passed` field is true. `aggregates.score` is not used for this decision. A first-run drop is not a verdict: step d.7 reruns it, and a drop that the step d.7 rerun confirms blocks the change. There is no tolerance for a confirmed drop.

## b. Consent and Cost

1. Every eval run uses model usage. Get the owner's consent for each run before starting it.
2. Pass a ceiling on every run: `--max-cost-usd <ceiling>`.
3. Consent for one run does not cover a rerun or a changed command. Ask again.
4. The comparison has one run per checkout and tier. Each run gets its own ceiling. The comparison runs several invocations, and the total of all paid runs must stay within the owner's total budget. Before starting a run, if the running total of finished runs (the sum of their `costUsd`) plus that run's ceiling would pass the total budget, stop and return to the owner. Record the running total with the comparison after each invocation.
5. If consent is withheld, no run happens. Do not ship the change on the strength of this procedure.
6. `--scaffold` runs each case's `scaffold.sh` as bash on the machine as the user running the command. Run evals only on code you have read, including every `scaffold.sh` in both checkouts.

## c. Cases and Checkouts

1. Cases live in `evals/`: each case folder holds `prompt.md`, `graders/*.md`, `case.yaml` and `scaffold.sh`. `scaffold.sh` builds the small test repository the case runs in. Each case has one rule.
2. The old and new checkouts must hold identical `evals/` directories. Run `diff -r -x results <old-path>/evals <new-path>/evals`. The no-skill copy (step d.1) is checked the same way against the new `evals/`: run `diff -r -x results <no-skill-path>/evals <new-path>/evals`. Continue only when both print nothing and exit 0.

## d. Steps

1. Name the three versions:
   - **old**: the base commit before the edit, in the old checkout. Make it with `git worktree add <old-path> <base-commit>`, where `<base-commit>` is the commit before the edit.
   - **new**: the edited tree, kept as the new checkout at `<new-path>`.
   - **no-skill**: a copy of the new tree with the skill's own directory removed, so the skill is absent. Its `evals/` directory is identical to the new one (checked in step c.2).
2. Run the old checkout once at the Economy tier and once at tier Standard, with 10 runs per case. Pass the tier as `--model <tier>`:
   `claude plugin eval <old-path> --runs 10 --model <tier> --judge-model <judge-model> --ablation none --scaffold --allow-tools Edit --no-publish --max-cost-usd <ceiling> --json <old-tier.json>`
   Write the Economy run to `<old-economy.json>` and the Standard run to `<old-standard.json>`.
3. Run the same command on `<new-path>` at the same two tiers, with `--json <new-economy.json>` and `--json <new-standard.json>`. Keep the same `--runs 10`, `--model`, `--judge-model`, `--scaffold`, and `--allow-tools Edit` on both.
4. Join each tier's old and new files, once per tier. The join prints one object per case: the case name, the tier, the old passing-run count, the new passing-run count, and `drop`, which is true when the new count is below the old count. A passing run is an entry of `arms.with` whose `passed` field is true; `aggregates.score` is not read.
   ```
   jq -n --arg tier <tier> --slurpfile o <old-tier.json> --slurpfile n <new-tier.json> '
     if ($o[0].cases | length) != ($n[0].cases | length)
     then error("case counts differ: old \($o[0].cases | length), new \($n[0].cases | length)")
     else . end
     | [ $o[0].cases[] as $a
         | [ $n[0].cases[] | select(.name == $a.name) ] as $m
         | (if ($m | length) == 1 then $m[0] else error("case \($a.name) must appear exactly once in new.json") end) as $b
         | {case: $a.name, tier: $tier,
            old: ([$a.arms.with[] | select(.passed == true)] | length),
            new: ([$b.arms.with[] | select(.passed == true)] | length)}
         | . + {drop: (.new < .old)} ]'
   ```
   Both files must hold the same number of cases. A case missing from new.json, or present more than once in it, stops the join with an error; it is never skipped.
5. Escalate to Premium. A case escalates when its Economy verdict and its Standard verdict under the count rule of step a.2 differ: one tier passes it and the other fails it, so `drop` is true on one tier and false on the other. Run each escalated case at the Premium tier: 10 runs per version, with `--model Premium` and `--case <case-name>`, each run with its own ceiling and the owner's consent. Join the Premium files with the step d.4 join. Premium runs no case that did not escalate.
6. A case whose `drop` is true on any tier is a drop: its new count is below its old count.
7. For a dropped case, rerun that case once on both checkouts at the tier where it dropped: add `--case <case-name>` and a new `--json` file name. The rerun needs the owner's consent and a ceiling.
8. If the rerun still shows a drop, the change is blocked.
9. If the rerun shows no drop, the change may ship. Record the rerun result with the comparison.

## e. Why These Flags

1. `--ablation none`: the default compares the plugin against no plugin and makes `tool_used: Skill` graders display-only. A comparison between two plugin versions needs those graders to count. The flag also halves the spend.
2. `--no-publish`: keeps the HTML report local.
3. `--scaffold --allow-tools Edit`: `--scaffold` is an opt-in that runs each case's `scaffold.sh` so the case has its test repository (without it the case runs in an empty folder), and the test repository's answers differ from the plugin's own files, so a session that reads the plugin folder instead gets the wrong answer; `--allow-tools Edit` is an operator grant that lets the `session-bootstrap-first` case edit its README; both are part of the owner's consent for the run.
4. Model tiers: the judge (`--judge-model`) runs at the Premium tier for the first skill whose comparison uses this procedure, and at the Standard setting for each later skill. Sessions (`--model`) run at the Economy tier and at tier Standard, as steps d.2 and d.3 state, and at the Premium tier only for escalated cases (step d.5). Use the same tiers on both checkouts. The tiers are defined in the Model Selection section of the subagent-driven-development skill; this note names tiers only, so the procedure does not change when a model name does.

## f. Failure Outcomes

1. A run that hits the ceiling exits 2 with partial results and gives no verdict. Either raise the ceiling with the owner's consent and rerun, or do not ship.
2. A case without a grader, a bad grader field, or a bad checkout path fails when the suite loads. No verdict exists.
3. A missing json file means no verdict.
4. Results are written under `evals/results/` in each checkout. That directory is gitignored.
5. An arm with a non-null `error` is rerun once. The rerun is a paid run, so step b.3 applies. If it errors again, report it as an arm error with its rerun result in the results. Never score it as 0 of 10.
6. A case that exits 2 on the ceiling is reported as partial, not as a verdict.

## g. Token Cost

1. Record the skill's on-invoke cost before and after the change, next to the eval comparison.
2. Run `claude --plugin-dir <old-path> plugin details story-to-ship`.
3. Run `claude --plugin-dir <new-path> plugin details story-to-ship`.
4. Confirm the output line `Source: story-to-ship@inline` in each run. It shows the command read the checkout, not the installed copy.
5. Find the skill's row under "Per-component" and read the `on-invoke` column. The readout rounds values; record the value as printed.
6. Use this number, not the chars/4 estimate in `SIZE_AND_COMPRESSION.md`, as the recorded saving.
7. Record one line per change in this format:
   `<skill>: <old on-invoke> -> <new on-invoke>; eval: <n> cases, no drop`

## h. Limits

1. Scores come from model runs. Ten runs per case per tier is the floor.
2. A case that scores the same with and without the plugin (the completion-claim case is one) does not prove the skill text matters.
3. A passing comparison shows no measured drop. It does not show the text is unneeded.
4. The join reads cases[].arms.with[].passed; check that field exists in the first --ablation none output before trusting the table.
5. Coverage: each eval case exercises one rule: `session-bootstrap-first` the first-tool-is-session-bootstrap rule, `completion-claim-evidence` the rule that a completion claim carries its evidence, `dispatch-passes-model` the rule that an Agent dispatch passes a model, `hold-rule-names-state` the rule that a hold rule names its state value, where it is stored, who clears it and what a repeat does, `shared-decisions-contradiction` the rule that a runner reports contradicting shared decisions instead of dispatching them. The two-stage-review cases follow, one line per group; the total is 23 two-stage-review cases:
   - `tsr-iron-law`: the two-stage-review Iron Law.
   - `tsr-before-1` to `tsr-before-4`: the BEFORE PROCEEDING items 1 to 4.
   - `tsr-redflag-1` to `tsr-redflag-7`: the Red Flag rows 1 to 7.
   - `tsr-rat-1` to `tsr-rat-11`: the Rationalization rows 1 to 11.

   A grader for a two-stage-review case checks behavior (an `llm` grader with focus `last_message`, or a `tool_used` grader with `input_match`), never a `tool_used` Skill call alone, because the no-skill copy cannot pass one. A skill with no case gets no result from this procedure: a passing comparison says nothing about it.
6. What each case does and does not show: `completion-claim-evidence` scored the same with and without the plugin in its recorded run, so it does not show that the plugin text matters. In the recorded run of `dispatch-passes-model`, the session without the plugin made no Agent call (the grader reported "Agent called 0x"), so that case's score does not measure whether the model was passed. `session-bootstrap-first` tests the hook text injected at session start and before the first prompt, not the skill body.
7. A session can read the plugin folder: a session may open the plugin's own files instead of the test repository. The scaffolded repositories hold answers that differ from the plugin's files, so such a session scores wrong, but a case that does not check the answer (the dispatch and bootstrap cases) cannot catch it.
