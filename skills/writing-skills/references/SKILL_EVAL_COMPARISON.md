---
title: "Old-Versus-New Eval Comparison"
description: "Procedure for comparing a shortened or reworded skill against its prior text with claude plugin eval: the rule of three for zero-event and all-event pairs, the grouping labels (`excluded: no signal`; `excluded: grouped with <kept>`; `unclassified: run no-skill first`; `error, no verdict`) and the grouping command, plus on-invoke token cost before and after."
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
2. Ship the changed skill only when no kept case shows a drop that the step d.6 rerun confirms. A first-run drop is not a verdict: step d.6 reruns it, and a confirmed drop blocks the change. There is no tolerance for a confirmed drop. An excluded case or a case with no verdict has no pass or fail result from this procedure; it gates the ship only through the full-suite run (section i, item 6).

## b. Consent and Cost

1. Every eval run uses model usage. Get the owner's consent for each run before starting it.
2. Pass a ceiling on every run: `--max-cost-usd <ceiling>`.
3. Consent for one run does not cover a rerun or a changed command. Ask again.
4. The comparison has two runs, one per checkout. Each run gets its own ceiling. The total is twice the ceiling.
5. If consent is withheld, no run happens. Do not ship the change on the strength of this procedure.
6. `--scaffold` runs each case's `scaffold.sh` as bash on the machine as the user running the command. Run evals only on code you have read, including every `scaffold.sh` in both checkouts.

## c. Cases and Checkouts

1. Cases live in `evals/`: each case folder holds `prompt.md`, `graders/*.md`, `case.yaml` and `scaffold.sh`. `scaffold.sh` builds the small test repository the case runs in. Each case has one rule.
2. Both checkouts must hold identical `evals/` directories. Run `diff -r -x results <old-path>/evals <new-path>/evals`. Continue only when it prints nothing and exits 0.

## d. Steps

1. Make the old checkout: `git worktree add <old-path> <base-commit>`, where `<base-commit>` is the commit before the edit. Keep the edited tree as the new checkout at `<new-path>`.
2. Run the old checkout:
   `claude plugin eval <old-path> --runs 14 --model <model> --judge-model <judge-model> --ablation none --scaffold --allow-tools Edit --no-publish --max-cost-usd <ceiling> --json <old.json>`
3. Run the same command on `<new-path>` with `--json <new.json>`. Keep the same `--runs`, `--model`, `--judge-model`, `--scaffold`, and `--allow-tools Edit` on both. The run count is 14 runs per kept case (section h, item 1). Step d.2 runs every case in the suite, so an excluded case or a case with no verdict also gets those 14 runs; no further run is made for it, and it has no pass or fail result (section i, item 6).
4. Join and print the per-case scores and the difference. The join reads every case in old.json. A case missing from new.json gets the row `error, no verdict` for that case, and the comparison has no verdict:
   `jq -n --slurpfile o <old.json> --slurpfile n <new.json> '[ $o[0].cases[] as $a | ([ $n[0].cases[] | select(.name==$a.name) ] | .[0]) as $b | if $b == null then {case:$a.name, verdict:"error, no verdict"} else {case:$a.name, old:$a.aggregates.score, new:$b.aggregates.score, diff:($b.aggregates.score-$a.aggregates.score)} end ]'`
5. A negative `diff` is a drop.
6. For a dropped case, rerun that case once on both checkouts: add `--case <case-name>` and a new `--json` file name. The rerun needs the owner's consent and a ceiling.
7. If the rerun still shows a drop, the change is blocked.
8. If the rerun shows no drop, the change may ship. Record the rerun result with the comparison.

## e. Why These Flags

1. `--ablation none`: the default compares the plugin against no plugin and makes `tool_used: Skill` graders display-only. A comparison between two plugin versions needs those graders to count. The flag also halves the spend.
2. `--no-publish`: keeps the HTML report local.
3. `--scaffold --allow-tools Edit`: `--scaffold` is an opt-in that runs each case's `scaffold.sh` so the case has its test repository (without it the case runs in an empty folder), and the test repository's answers differ from the plugin's own files, so a session that reads the plugin folder instead gets the wrong answer; `--allow-tools Edit` is an operator grant that lets the `session-bootstrap-first` case edit its README; both are part of the owner's consent for the run.
4. Model tiers: run the sessions at the Economy tier and the judge at the Standard tier (`--model` and `--judge-model`), the same on both checkouts. The tiers are defined in the Model Selection section of the subagent-driven-development skill; this note names tiers only, so the procedure does not change when a model name does.

## f. Failure Outcomes

1. A run that hits the ceiling exits 2 with partial results and gives no verdict. Either raise the ceiling with the owner's consent and rerun, or do not ship.
2. A case without a grader, a bad grader field, or a bad checkout path fails when the suite loads. No verdict exists.
3. A missing json file means no verdict.
4. Results are written under `evals/results/` in each checkout. That directory is gitignored.

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

1. Scores come from model runs. Use 14 runs per kept case; that is the run count for a kept case that must show a 20-point drop.
2. A case that scores the same with and without the plugin (the completion-claim case is one) does not prove the skill text matters.
3. A passing comparison shows no measured drop. It does not show the text is unneeded. An excluded case carries no verdict and gates a ship at the full-suite interval (section i, item 6).
4. The join reads cases[].aggregates.score; check that field exists in the first --ablation none output before trusting the table.
5. Coverage: each eval case exercises one rule: `session-bootstrap-first` the first-tool-is-session-bootstrap rule, `completion-claim-evidence` the rule that a completion claim carries its evidence, `dispatch-passes-model` the rule that an Agent dispatch passes a model, `hold-rule-names-state` the rule that a hold rule names its state value, where it is stored, who clears it and what a repeat does, `shared-decisions-contradiction` the rule that a runner reports contradicting shared decisions instead of dispatching them. A skill with no case gets no result from this procedure: a passing comparison says nothing about it.
6. What each case does and does not show: `completion-claim-evidence` scored the same with and without the plugin in its recorded run, so it does not show that the plugin text matters. In the recorded run of `dispatch-passes-model`, the session without the plugin made no Agent call (the grader reported "Agent called 0x"), so that case's score does not measure whether the model was passed. `session-bootstrap-first` tests the hook text injected at session start and before the first prompt, not the skill body.
7. A session can read the plugin folder: a session may open the plugin's own files instead of the test repository. The scaffolded repositories hold answers that differ from the plugin's files, so such a session scores wrong, but a case that does not check the answer (the dispatch and bootstrap cases) cannot catch it.

## i. Pair Bounds, Grouping and Labels

1. Group the run files with `python3 skills/writing-skills/scripts/eval_grouping.py label=path [label=path ...]`, one `label=path` item per run file. The caller chooses the labels. Pooling works by repeating a label: run files given the same label are concatenated under that label, in argument order. A label for a no-skill run starts with the prefix `no-skill`. Build that run file from a default-ablation run (item 8): the script reads only `cases[].arms.with`, so the records of the no-plugin arm of that run must sit under `arms.with` in the file the script reads. The arm's key name is not shown in this repository; read it from a default-ablation output before you copy the records.
2. A kept case is a case the grouping does not exclude. The grouping compares two cases on the labels they share, using each case's pass rate under each label. Cases are visited in sorted name order, and the first case of a group is its kept case. A case joins the earliest kept case with which it shares at least 3 labels and whose correlation with it is at least 0.9. The correlation is the Pearson correlation of the two rate lists over the shared labels. Each group keeps one case, and its other members are excluded. A case whose pass rate is the same under every label has no correlation and never joins a group.
3. Exact one-sided 95 percent bound: when a case has the same pass rate under every label and that rate is 0 or 1, the bound is `1 - 0.05 ** (1/n)`. At rate 0 (0 passes in n runs) it is the one-sided 95 percent upper bound on the pass rate. At rate 1 (n passes in n runs) it is the one-sided 95 percent upper bound on the fail rate. Here n is the smallest scored-run count that any label holds for that case, counting every run file under each label. It is not a sum over labels, so 4 labels of 4 runs give n = 4. The script prints the value as `bound <value>` to 3 places. The exact bound is the exact form of the rule of three; 3/n is its approximation at zero events.
4. A 0-vs-0 or n-vs-n pair is not evidence that the new text keeps the behavior.
5. Every line the script prints is one of these. Each label is quoted as printed:
   - `<path>: error, no verdict`: the script cannot use that run file. This covers a file that is unreadable, is not valid JSON, lacks a cases[] list or a case's arms.with[] list, holds a record whose passed is not a true or false value, or holds a record whose error is not null. The script prints this line for each such file, then still prints the lines for the other files and cases. In step d.4 the same label marks a case missing from new.json; there the jq join prints it, and the script is not involved.
   - `<case>: excluded: no signal`: the case has the same pass rate under every label, and one label starts with `no-skill`. The case carries no verdict. When that shared rate is 0 or 1, the line also carries `bound <value>` and `(not evidence of keeping the behavior)`.
   - `<case>: unclassified: run no-skill first`: the case has the same pass rate under every label, and no label starts with `no-skill`. The case is kept, not excluded. When its rate is 0 or 1, the line carries the same bound and note. Run a no-skill run, then classify again.
   - `<case>: excluded: grouped with <kept>`: the case is a member of the group that keeps `<kept>`. The case carries no verdict.
   - `group kept <kept>: <members>`: one line per kept case that has members; the members are separated by `, `. A kept case with no members prints no group line.
   - `<case>: varies`: a kept case whose pass rate differs across labels and that has a computable correlation (3 or more shared labels, nonzero variance in both cases) with at least one other case.
   - `<case>: not groupable`: a kept case whose pass rate differs across labels and that has no computable correlation with any other case.
   - `<case>: no runs under <label>`: the case has no scored run under that label. The case gets no excluded or unclassified line, and the grouping uses the labels it does have.

   The script exits 0 when every run file is read, 1 when any run file has the error label, and 2 when an argument is not `label=path`.
6. An excluded label carries no verdict. An excluded case gates a ship at the full-suite interval. Run the full suite before each ship: the changed skill's own cases, grouped-away and no-signal cases included. This procedure states no pass or fail rule for a case with no verdict.
7. Pool only across grader rounds with identical grader files. The caller chooses the labels, and the script does not check grader files.
8. Make one default-ablation run per case, when a case is first classified or when its grader changes. Keep `--ablation none` for comparisons (section d).
