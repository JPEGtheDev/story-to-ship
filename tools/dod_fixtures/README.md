# DoD fixture harness

## 1. Purpose

This directory holds a fixture-proof harness for the Definition of Done
(DoD) canon skill chain. "Canon" here means the ratified Definition of
Done document a repository keeps at `docs/DOD.md`. The skill chain is a
set of skills that generate a user story's Definition of Done section
from a project's canon, ratify or re-ratify that canon, and check a
completion claim's evidence against it. Some of that skill work is only
considered fully proven once an actual, captured run of the skill
against one of these fixtures shows the expected pass/fail behavior end
to end, rather than being proven by code review alone. `check-markers.sh`
is the script that turns a captured fixture-run transcript into a
pass/fail verdict: it checks a run's output file for the pinned marker
strings defined below and asserts each one is present (a positive
assertion) or absent (a negative assertion). A marker counts as present
only when some transcript line starts with it; a line that merely
mentions the marker text elsewhere -- for example, in a sentence
describing what did or did not happen -- does not count.

The fixtures in this directory are synthetic test data for fictional
apps. The apps they describe, their code paths, and every request,
claim, and command output they quote are invented. They exist only to
exercise the Definition of Done tooling, and they describe no real
repository.

## 2. Marker definitions

The three marker strings below are quoted verbatim from the defining-done
skill's Definition of Done canon template reference, Section C ("Consumer
notes"), which is their authoritative source. That reference file is
authoritative if this README and it ever disagree.

- `DOD-VIOLATION: <layer>` -- the story generator's refusal marker,
  emitted when a story omits a layer that is always required, with no
  category-tagged "not applicable" line explaining why.
- `DOD-GATE: FAIL <layer>` -- the completion gate's failure marker,
  emitted when a completion claim lacks evidence for an always-required
  layer, or for a conditional layer whose trigger condition fired.
- `DOD-STALE: canon v<N> behind taxonomy v<M>` -- emitted by either
  consumer when the DoD document's `Stamp: vN` is older than the current
  stamp of the taxonomy (the master list of verification layers) it was
  ratified against. The document is still consumed: staleness is a
  currency warning, not a refusal trigger.

A separate condition -- the DoD document existing on disk with uncommitted
local edits -- is deliberately marker-less: no `DOD-` marker of any kind
names it. The consumer states the uncommitted edit plainly and continues,
consuming the file as it currently reads. See the dirty-canon scenario in
Section 3 for how this is fixture-proven.

`<layer>`, `<N>`, and `<M>` are parameterized tails (a layer's identifying
key, or version numbers). `check-markers.sh` asserts on the fixed prefix
up to that parameter, not the full parameterized string:

| Marker | Fixed-prefix literal to assert |
|---|---|
| `DOD-VIOLATION: <layer>` | `DOD-VIOLATION:` |
| `DOD-GATE: FAIL <layer>` | `DOD-GATE: FAIL` |
| `DOD-STALE: canon v<N> behind taxonomy v<M>` | `DOD-STALE: canon v` |

## 3. Run procedure

Each fixture scenario below is a pairing of an input file (a story
request, a completion claim, a DoD document, or a taxonomy) with the
expected outcome once that input is dispatched to the relevant skill --
a marker, for every scenario but delta re-ratification, which instead
checks the resulting document for byte-preservation (see below). Use
`run-scenario.sh` (in this directory) to perform or print the mechanical
steps for a scenario: placing the right DoD document at `docs/DOD.md` in
a scratch copy of the repository, naming the request or claim text to
feed the dispatched agent, and invoking `check-markers.sh` against the
captured transcript. Run `./run-scenario.sh --help` for its usage text.

The scenarios this harness covers: one positive and one negative case per
marker-emitting behavior it proves, plus two scenarios that each prove a
non-marker behavior and so carry their own pass condition instead of a
`check-markers.sh` require/forbid pairing -- delta re-ratification (a
byte-preservation check on the resulting document) and dirty-canon (a
negative control on all three markers, paired with a transcript read for
the plain-statement-and-continue behavior itself):

**Story-generator scenarios** (input file: `story-request-scenarios.md`,
DoD document: `story-request-canon.md`):
```
tools/dod_fixtures/check-markers.sh <violating-story-output> --require 'DOD-VIOLATION:'
tools/dod_fixtures/check-markers.sh <compliant-story-output> --forbid 'DOD-VIOLATION:'
```

**No-canon fallback scenario** (`no-canon-fallback` in `run-scenario.sh`;
input file: `story-request-scenarios.md` Case C, run with no file at
`docs/DOD.md`): no document exists for this scenario, so `DOD-VIOLATION:`
must never fire -- this is a forbid-only assertion (there is no separate
marker for "fallback statement shown"; that text is checked by reading
the captured output directly):
```
tools/dod_fixtures/check-markers.sh <no-canon-output> --forbid 'DOD-VIOLATION:'
```

**Completion-gate scenarios** (input file:
`completion-claim-scenarios.md`, DoD document:
`completion-claim-canon.md`):
```
tools/dod_fixtures/check-markers.sh <evidence-missing-output> --require 'DOD-GATE: FAIL'
tools/dod_fixtures/check-markers.sh <evidence-complete-output> --forbid 'DOD-GATE: FAIL'
```

**Stale-stamp scenarios** (one run per consumer -- story generator and
completion gate -- each with a stale document variant embedded in its
scenario file, plus a fresh negative control). A stale `Stamp:` is the
single induced defect in each variant (see Case D in
`story-request-scenarios.md` and Case C in
`completion-claim-scenarios.md`). The first command below is what
`run-scenario.sh` prints for the `story-stale-canon` and
`completion-stale-canon` scenarios. The second is the fresh negative
control, run by hand against a transcript captured with the clean
document in place -- no separate scenario exists for it:
```
tools/dod_fixtures/check-markers.sh <stale-canon-output> --require 'DOD-STALE: canon v'
tools/dod_fixtures/check-markers.sh <fresh-canon-output> --forbid 'DOD-STALE: canon v'
```

**Delta re-ratification scenario** (existing canon:
`delta-reratification-canon.md`, ratified against
`delta-reratification-taxonomy-v1.md`; current taxonomy:
`delta-reratification-taxonomy-v2.md`, which adds one layer):
```
tools/dod_fixtures/run-scenario.sh delta-reratification
```
This exercises delta re-ratification: dispatch the defining-done skill's
re-ratification interview against the v2 taxonomy with the v1-ratified
canon already in place, and confirm the interview elicits a ruling only
for the added layer. This scenario has no marker check --
`run-scenario.sh` rejects `--check` for it by design, since it emits no
`DOD-VIOLATION:`, `DOD-GATE: FAIL`, or `DOD-STALE:` marker. Its pass
condition is read directly from the transcript and the resulting
document: the canon produced by the interview must differ from the input
canon by exactly the new ruling line(s) plus the `Stamp:` line update,
with every other byte preserved.

**Dirty-canon scenario** (input file: `completion-claim-scenarios.md`
Case B; DoD document: `completion-claim-canon.md`, committed as a
baseline in the scratch worktree and then given one uncommitted local
edit):
```
tools/dod_fixtures/run-scenario.sh dirty-canon --worktree <scratch-worktree>
tools/dod_fixtures/check-markers.sh <dirty-canon-output> --forbid 'DOD-VIOLATION:' --forbid 'DOD-GATE: FAIL' --forbid 'DOD-STALE: canon v'
```
This exercises the completion-gate consumer's uncommitted-edit rule: with
`docs/DOD.md` committed and then locally edited without committing, the
consumer states the uncommitted edit plainly and continues, evaluating
the claim against the file as it currently reads. `run-scenario.sh`
proves the induced state itself before any dispatch happens -- it fails
loudly unless `git diff --numstat -- docs/DOD.md` in the scratch worktree
reads exactly `1<TAB>1<TAB>docs/DOD.md` and `git diff -- docs/DOD.md`
contains the edit text -- so a scenario run that reaches Step 3 has a
provably real, scoped uncommitted edit behind it, not an accidentally
dirty worktree. The `check-markers.sh` invocation above is a negative
control only: forbidding all three markers rules out a violation, a gate
failure, and a staleness claim, but a forbid-only pass does not by itself
prove the consumer noticed and disclosed the uncommitted edit -- it would
also pass if the consumer silently ignored the edit entirely. This
scenario's actual pass condition is a transcript read: confirm the
captured output states the uncommitted edit plainly, in prose, and that
evaluation continues rather than refusing.

Placing a fixture document at `docs/DOD.md` (every scenario above except
no-canon-fallback) leaves the scratch worktree dirty relative to whatever
it had committed before the run -- that is simply what `cp`'ing a fixture
document does. Dirty-canon is the only scenario that commits the placed
document as a baseline first and only then edits it locally; that commit
step is what turns its induced edit into a single, scoped, attributable
change on top of a known baseline, rather than an artifact of the
placement mechanism shared by every other scenario.

Scope note: dirty-canon fixture-proves the uncommitted-edit rule for the
completion-gate consumer only. The story generator carries the identical
warn-and-continue rule for an uncommitted `docs/DOD.md`, but no scenario
in this harness exercises it there yet -- that is a named follow-up
candidate, not a proven case.

A `RESULT: PASS (N/N)` line and exit code 0 from every `check-markers.sh`
invocation in a marker-based scenario is what confirms that scenario's
behavior end to end. Any `RESULT: FAIL` or nonzero exit means the
behavior did not match what the scenario expects; treat it as a real
finding rather than re-running until it passes. The delta re-ratification
scenario has no `check-markers.sh` invocation; its own byte-preservation
pass condition, above, is what confirms its behavior instead. Dirty-canon
does have a `check-markers.sh` invocation, but that invocation alone is
not sufficient either -- see its pass condition above.

## 4. Consent note

Running a fixture scenario means dispatching a real agent skill, which is
a spend-bearing operation, not a free static check. Get the user's
explicit consent before each run. This applies even to re-running a
scenario that already passed once -- to chase a flaky result, re-verify
after a later edit, or extend coverage -- since re-running is still a new
spend-bearing invocation, not covered by an earlier consent.
