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

The four marker strings below are quoted verbatim from the defining-done
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
- `DOD-MALFORMED: <reason>` -- emitted by either consumer when
  `docs/DOD.md` exists but its structure cannot be parsed (a missing or
  unparseable `Stamp:` line, or a ruling line matching none of the three
  forms in Section A.3 of the canon template). The refusal states exactly
  what failed to parse: `<reason>` carries that one-line diagnostic on
  the marker line itself. Unlike the other three markers, this one is a
  refusal to evaluate at all -- the consumer must not also emit a verdict
  marker from a canon it refused to consume.

A separate condition -- the DoD document existing on disk with uncommitted
local edits -- is deliberately marker-less: no `DOD-` marker of any kind
names it. The consumer states the uncommitted edit plainly and continues,
consuming the file as it currently reads. See the dirty-canon and
dirty-canon-generator scenarios in Section 3 for how this is
fixture-proven for each consumer.

`<layer>`, `<N>`, `<M>`, and `<reason>` are parameterized tails (a layer's
identifying key, version numbers, or a one-line parse diagnostic).
`check-markers.sh` asserts on the fixed prefix up to that parameter, not
the full parameterized string:

| Marker | Fixed-prefix literal to assert |
|---|---|
| `DOD-VIOLATION: <layer>` | `DOD-VIOLATION:` |
| `DOD-GATE: FAIL <layer>` | `DOD-GATE: FAIL` |
| `DOD-STALE: canon v<N> behind taxonomy v<M>` | `DOD-STALE: canon v` |
| `DOD-MALFORMED: <reason>` | `DOD-MALFORMED:` |

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
marker-emitting behavior it proves, plus four scenarios whose pass
condition is not fully captured by a `check-markers.sh` require/forbid
pairing alone, so each carries its own pass condition in addition --
delta re-ratification (no marker check at all; a byte-preservation check
on the resulting document instead), evidence-complete (a forbid-only
negative control on `DOD-GATE: FAIL` that a legitimate grounding-driven
failure can also trip, since the completion gate consumer is permitted to
ground cited evidence against the repo under evaluation -- see the
completion-gate scenarios entry below for the two-tier read that resolves
it), dirty-canon (a forbid-only negative control on all three markers,
paired with a transcript read for the plain-statement-and-continue
behavior itself, with the same grounding-driven caveat applying to its
`DOD-GATE: FAIL` forbid specifically), and dirty-canon-generator (the
story-generator analogue: a forbid-only negative control on all three of
its markers, paired with the same kind of transcript read, but with no
grounding-driven caveat on any of its forbids, since the story generator
has no `DOD-GATE: FAIL` equivalent); malformed-canon's entry below
carries its own lighter confirmation-read note, not a second-tier pass
condition:

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

**Dirty-canon (story-generator) scenario** (input file:
`story-request-scenarios.md` Case B; DoD document:
`story-request-canon.md`, committed as a baseline in the scratch
worktree and then given one uncommitted local edit):
```
tools/dod_fixtures/run-scenario.sh dirty-canon-generator --worktree <scratch-worktree>
tools/dod_fixtures/check-markers.sh <dirty-canon-generator-output> --forbid 'DOD-VIOLATION:' --forbid 'DOD-STALE: canon v' --forbid 'DOD-MALFORMED:'
```
This is the story-generator analogue of the completion-gate's dirty-canon
scenario below, exercising the identical uncommitted-edit rule the
user-story-generator skill carries: with `docs/DOD.md` committed and
then locally edited without committing, the generator states the
uncommitted edit plainly and continues, generating the story's
Definition of Done section from the file as it currently reads.
`run-scenario.sh` proves the induced state itself before any dispatch
happens -- it fails loudly unless `git diff --numstat -- docs/DOD.md` in
the scratch worktree reads exactly `1<TAB>1<TAB>docs/DOD.md` and
`git diff -- docs/DOD.md` contains the edit text -- so a scenario run
that reaches Step 3 has a provably real, scoped uncommitted edit behind
it, not an accidentally dirty worktree. The `check-markers.sh` invocation
above is a negative control only: forbidding all three markers rules out
a refusal, a staleness claim, and a malformed-canon refusal, but a
forbid-only pass does not by itself prove the generator noticed and
disclosed the uncommitted edit -- it would also pass if the generator
silently ignored the edit entirely. Unlike dirty-canon's `DOD-GATE: FAIL`
forbid, none of this scenario's three forbids carries a grounding-driven
caveat: the story generator has no `DOD-GATE: FAIL` equivalent, Case B's
request drops no canon layer (so no legitimate `DOD-VIOLATION:`), the
placed canon's `Stamp: v1` matches the taxonomy's current stamp (so no
legitimate `DOD-STALE: canon v`), and the placed canon is well-formed (so
no legitimate `DOD-MALFORMED:`) -- any forbid failure here is a
straightforward real finding. This scenario's actual pass condition is a
transcript read: confirm the captured output states the uncommitted edit
plainly, in prose, and that generation continues rather than refusing
(e.g. a sentence naming `docs/DOD.md` and noting that it carries
uncommitted local edits, with the story still produced; the exact
phrasing is free, matching the consumer rule's own "state plainly"
wording rather than any fixed required phrase or marker).

**Completion-gate scenarios** (input file:
`completion-claim-scenarios.md`, DoD document:
`completion-claim-canon.md`):
```
tools/dod_fixtures/check-markers.sh <evidence-missing-output> --require 'DOD-GATE: FAIL'
tools/dod_fixtures/check-markers.sh <evidence-complete-output> --forbid 'DOD-GATE: FAIL'
```
The evidence-complete forbid above is a first-pass screen, not the
scenario's full pass condition. The completion gate consumer is permitted
(not required) to ground cited evidence against the repo under
evaluation, and this fixture's claim cites fictional paths
(`tools/ingest/dedupe.py` and its test module) that do not exist in this
repo -- so a consumer that grounds may legitimately emit `DOD-GATE: FAIL`
here even though the claim's evidence is structurally complete. If the
forbid check passes outright, the scenario is confirmed with no further
read needed. If it fails, read the emitted `DOD-GATE: FAIL` line in the
transcript: a line whose stated reason is the cited path's absence from
the repo (grounding-driven) is not a scenario failure -- record it as a
pass with the grounding disclosure noted; a line whose stated reason is
missing or generic evidence for a layer is a real scenario failure, since
Case B's evidence is deliberately structurally complete.

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
also pass if the consumer silently ignored the edit entirely. If the
forbid check instead fails specifically on `DOD-GATE: FAIL`, apply the
same two-tier read the evidence-complete scenario uses above (this
scenario dispatches the same Case B claim text, citing the same fictional
paths): a grounding-driven reason is not a scenario failure and does not
by itself contradict the uncommitted-edit disclosure being sought; a
missing/generic-evidence reason is a real failure, same as
evidence-complete. A forbid failure on `DOD-VIOLATION:` or
`DOD-STALE: canon v` instead has no such caveat -- either is a
straightforward real finding. Either way, this scenario's actual pass
condition is a transcript read: confirm the
captured output states the uncommitted edit plainly, in prose, and that
evaluation continues rather than refusing (e.g. a sentence naming
`docs/DOD.md` and noting that it carries uncommitted local edits; the
exact phrasing is free, matching the consumer rule's own "state plainly"
wording rather than any fixed required phrase or marker).

Placing a fixture document at `docs/DOD.md` (every scenario above except
no-canon-fallback) leaves the scratch worktree dirty relative to whatever
it had committed before the run -- that is simply what `cp`'ing a fixture
document does. Dirty-canon, dirty-canon-generator, and malformed-canon
are the only scenarios that commit the placed document as a baseline
first and only then apply a local mutation; that commit step is what
turns each one's induced edit into a single, scoped, attributable change
on top of a known baseline, rather than an artifact of the placement
mechanism shared by every other scenario.

Scope note: dirty-canon and dirty-canon-generator both fixture-prove
the warn-and-continue uncommitted-edit rule now -- dirty-canon for the
completion-gate consumer, dirty-canon-generator for the story
generator's uncommitted `docs/DOD.md` case. Both are backed by
captured runs (`tools/dod_fixtures/runs/dirty-canon.out`,
`tools/dod_fixtures/runs/dirty-canon-generator.out`) on the
`agent/dod-scenario-runs` evidence branch, each stating the
uncommitted edit plainly, in prose, and continuing rather than
refusing.

**Malformed-canon scenario** (input file: `completion-claim-scenarios.md`
Case B; DoD document: `completion-claim-canon.md`, committed as a
baseline in the scratch worktree and then given one uncommitted
structural mutation -- its terminal `Stamp: v1` line deleted):
```
tools/dod_fixtures/run-scenario.sh malformed-canon --worktree <scratch-worktree>
tools/dod_fixtures/check-markers.sh <malformed-canon-output> --require 'DOD-MALFORMED:' --forbid 'DOD-VIOLATION:' --forbid 'DOD-GATE: FAIL' --forbid 'DOD-STALE: canon v'
```
This exercises the malformed-canon refusal rule shared by both
consumers: with `docs/DOD.md` present but missing its terminal `Stamp:`
line, the consumer MUST refuse to evaluate the claim, emit
`DOD-MALFORMED: <reason>` naming what failed to parse, and must not also
emit a verdict marker from evaluating a canon it refused to consume.
`run-scenario.sh` proves the induced state itself before any dispatch
happens -- it fails loudly unless no line in the mutated `docs/DOD.md`
starts with `Stamp:`, so a scenario run that reaches Step 3 has a
provably malformed document behind it, not an accidentally-truncated
fixture. Unlike dirty-canon's forbid-only screen, this
`check-markers.sh` invocation is close to a full pass condition on its
own: the `--require 'DOD-MALFORMED:'` half is a positive assertion that
the refusal marker was actually emitted, not just an absence of the
verdict markers. It is still worth a quick transcript read to confirm
the emitted diagnostic actually names the missing `Stamp:` line (per the
marker's own `<reason>` requirement) rather than some unrelated parse
complaint, but that is a confirmation read, not a second-tier ambiguity
resolution like evidence-complete's or dirty-canon's grounding-driven
caveat -- malformed-canon has no such caveat, since a missing `Stamp:`
line is a purely structural, non-grounded condition: a correctly
refusing consumer never reaches evidence evaluation, so it cannot
legitimately emit `DOD-GATE: FAIL` here for a grounding reason either.

A `RESULT: PASS (N/N)` line and exit code 0 from every `check-markers.sh`
invocation in a marker-based scenario is what confirms that scenario's
behavior end to end, with one named exception. For every scenario except
evidence-complete and dirty-canon, any `RESULT: FAIL` or nonzero exit
means the behavior did not match what the scenario expects; treat it as
a real finding rather than re-running until it passes. Evidence-complete
forbids `DOD-GATE: FAIL` only; dirty-canon forbids all three markers,
including `DOD-GATE: FAIL`. In both, a `RESULT: FAIL` caused specifically
by the `DOD-GATE: FAIL` assertion failing can be either a real finding or
a legitimate grounding-driven failure -- read that line's stated reason
per the two-tier condition in their scenario entries above before ruling
either way. A `RESULT: FAIL` caused by any other assertion in either
scenario (the `DOD-VIOLATION:` or `DOD-STALE: canon v` forbids in
dirty-canon) is still a straightforward real finding, same as every other
scenario. The delta re-ratification scenario has no `check-markers.sh`
invocation; its own byte-preservation pass condition, above, is what
confirms its behavior instead. Dirty-canon does have a `check-markers.sh`
invocation, but that invocation alone is not sufficient either -- see its
pass condition above. Dirty-canon-generator likewise has a
`check-markers.sh` invocation that is not sufficient alone -- see its
pass condition above; unlike dirty-canon's, none of its three forbids
carries a grounding-driven caveat, since the story generator has no
`DOD-GATE: FAIL` equivalent, so any `RESULT: FAIL` for
dirty-canon-generator is a straightforward real finding regardless of
which forbid it comes from. Malformed-canon also forbids `DOD-GATE: FAIL`
(alongside its required `DOD-MALFORMED:` and its other two forbids), but
it is not part of this two-scenario exception: a correctly refusing
consumer never reaches evidence evaluation, so any `RESULT: FAIL` for
malformed-canon, on any assertion, is a straightforward real finding
with no grounding-driven read needed.

## 4. Consent note

Running a fixture scenario means dispatching a real agent skill, which is
a spend-bearing operation, not a free static check. Get the user's
explicit consent before each run. This applies even to re-running a
scenario that already passed once -- to chase a flaky result, re-verify
after a later edit, or extend coverage -- since re-running is still a new
spend-bearing invocation, not covered by an earlier consent.
