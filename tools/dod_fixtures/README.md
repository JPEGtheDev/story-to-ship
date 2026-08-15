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
- `DOD-HASH: MISMATCH` -- emitted by either consumer when the recomputed
  content hash does not match the DoD document's `Content-hash:` footer.
  This is a warn-and-consume check: the document is still read and used,
  so this marker signals a trust flag, not a parse failure.
- `DOD-STALE: canon v<N> behind taxonomy v<M>` -- emitted by either
  consumer when the DoD document's `Stamp: vN` is older than the current
  stamp of the taxonomy (the master list of verification layers) it was
  ratified against. The document is still consumed: staleness is a
  currency warning, not a refusal trigger.

`<layer>`, `<N>`, and `<M>` are parameterized tails (a layer's identifying
key, or version numbers). `check-markers.sh` asserts on the fixed prefix
up to that parameter, not the full parameterized string:

| Marker | Fixed-prefix literal to assert |
|---|---|
| `DOD-VIOLATION: <layer>` | `DOD-VIOLATION:` |
| `DOD-GATE: FAIL <layer>` | `DOD-GATE: FAIL` |
| `DOD-HASH: MISMATCH` | `DOD-HASH: MISMATCH` (no parameter, use in full) |
| `DOD-STALE: canon v<N> behind taxonomy v<M>` | `DOD-STALE: canon v` |

## 3. Run procedure

Each fixture scenario below is a pairing of an input file (a story
request, a completion claim, or a DoD document) with the expected
marker outcome once that input is dispatched to the relevant skill. Use
`run-scenario.sh` (in this directory) to perform or print the mechanical
steps for a scenario: placing the right DoD document at `docs/DOD.md` in
a scratch copy of the repository, naming the request or claim text to
feed the dispatched agent, and invoking `check-markers.sh` against the
captured transcript. Run `./run-scenario.sh --help` for its usage text.

The scenarios this harness covers, one positive and one negative case per
behavior it proves:

**Story-generator scenarios** (input file: `story-request-scenarios.md`,
DoD document: `story-request-canon.md`):
```
tools/dod_fixtures/check-markers.sh <violating-story-output> --require 'DOD-VIOLATION:'
tools/dod_fixtures/check-markers.sh <compliant-story-output> --forbid 'DOD-VIOLATION:'
```

**No-canon fallback scenario** (input file: `story-request-scenarios.md`
Case C, run with no file at `docs/DOD.md`): no document exists for this
scenario, so `DOD-VIOLATION:` must never fire -- this is a forbid-only
assertion (there is no separate marker for "fallback statement shown";
that text is checked by reading the captured output directly):
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

**Stale-stamp and tampered-hash scenarios** (one run per consumer --
story generator and completion gate -- each with a stale/tampered
document variant embedded in its scenario file, plus a fresh/untampered
negative control). The fixtures in this directory combine both defects
into one variant document (see Case D in `story-request-scenarios.md`
and Case C in `completion-claim-scenarios.md`), so the expected marker
check requires both markers from a single transcript. This is the
actual command `run-scenario.sh` prints for these scenarios:
```
tools/dod_fixtures/check-markers.sh <stale-tampered-output> --require 'DOD-STALE: canon v' --require 'DOD-HASH: MISMATCH'
tools/dod_fixtures/check-markers.sh <fresh-untampered-output> --forbid 'DOD-STALE: canon v' --forbid 'DOD-HASH: MISMATCH'
```
Illustrative only -- not shipped in this directory: a setup that
isolated staleness or hash-tamper into two separate documents, instead
of the one combined variant these fixtures ship, would assert the one
relevant marker per file:
```
tools/dod_fixtures/check-markers.sh <stale-only-output> --require 'DOD-STALE: canon v'
tools/dod_fixtures/check-markers.sh <tampered-only-output> --require 'DOD-HASH: MISMATCH'
```

A `RESULT: PASS (N/N)` line and exit code 0 from every invocation in a
scenario is what confirms that scenario's behavior end to end. Any
`RESULT: FAIL` or nonzero exit means the behavior did not match what the
scenario expects; treat it as a real finding rather than re-running until
it passes.

## 4. Consent note

Running a fixture scenario means dispatching a real agent skill, which is
a spend-bearing operation, not a free static check. Get the user's
explicit consent before each run. This applies even to re-running a
scenario that already passed once -- to chase a flaky result, re-verify
after a later edit, or extend coverage -- since re-running is still a new
spend-bearing invocation, not covered by an earlier consent.
