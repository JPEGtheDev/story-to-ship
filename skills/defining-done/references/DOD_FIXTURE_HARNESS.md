# Definition of Done Fixture Harness: When to Re-run It

The fixture harness in `tools/dod_fixtures/` checks captured transcripts of the
Definition of Done skills for the pinned marker lines. It is not part of
continuous integration, because each model-backed run costs money. Each such run
needs the owner's consent every time, including a re-run of a scenario that
already passed.

## When to re-run

Re-run the harness after any change to:

- a marker string, a marker's emit condition, or the canon parse rules, in the
  defining-done, verification-before-completion, or user-story-generator skills;
- a rule a scenario also proves, even though the change touches no marker string:
  the uncommitted-edit warning, the no-canon fallback, delta re-ratification, or
  the comparison of the canon's Stamp against the taxonomy's Stamp;
- the bare-line emission format of a marker. `check-markers.sh` matches a marker
  only at the start of a line.

The authoritative marker definitions are Section C of DOD_TEMPLATE.md, in this
directory. The harness README defers to it.

## How to run

Run every command from the repository root (`git rev-parse --show-toplevel` finds
it). The harness lives in a repository checkout that contains
`tools/dod_fixtures/`.

- `tools/dod_fixtures/run-scenario.sh --list` lists the scenarios.
  `tools/dod_fixtures/README.md`, Section 3, holds the per-scenario procedure.
- Free step: check an already captured transcript.
  `tools/dod_fixtures/check-markers.sh <transcript> --require '<literal>'`
  `tools/dod_fixtures/check-markers.sh <transcript> --forbid '<literal>'`
- Paid step: dispatch a skill against a scenario to capture a transcript. This
  needs the owner's consent per run. If consent is not given, the pull request
  must state which step was not run. A marker change is not proven without a run.
- The dirty-canon, dirty-canon-generator and malformed-canon scenarios need an
  unrelated scratch git repository (made with `git init`), not a worktree of this
  repository. `run-scenario.sh` refuses this repository and its worktrees.
- Captured transcripts are not kept on the main branch. Each run captures its own.

## What a pass looks like

- Marker scenarios: `check-markers.sh` prints `RESULT: PASS (N/N)` and exits 0.
  Exit 1 is a failed assertion. Exit 2 is a usage error (bad file or flag), not a
  marker finding.
- A `RESULT: FAIL` is a finding. Do not re-run hoping for a pass. One exception, for
  evidence-complete and dirty-canon: a failed `DOD-GATE: FAIL` forbid needs a read
  of the emitted line's stated reason (grounding-driven or missing evidence). The
  README holds the full rule.
- A plain PASS is not enough for these scenarios:
  - dirty-canon and dirty-canon-generator: the checks are forbid-only. Also read
    the transcript to confirm the uncommitted edit is stated plainly and the run
    continues.
  - delta-reratification: no `check-markers.sh` run exists for it. The pass is
    that the resulting canon differs from the input by exactly the new ruling
    lines plus the Stamp line.
  - malformed-canon: confirm the diagnostic names the missing Stamp line.
- A forbid-only pass on an empty or truncated transcript proves nothing. Confirm
  the transcript is non-empty. A marker that is indented, bulleted or quoted is
  not counted by either flag.
