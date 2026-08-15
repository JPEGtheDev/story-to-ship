# Completion-claim scenario fixtures

## 0. Purpose and design notes

This file carries three scenarios dispatched against the
verification-before-completion skill: the Definition of Done
completion-gate check (`DOD-GATE: FAIL <layer>` on missing or generic
evidence, silent pass on complete evidence) and a stale-stamp variant
that exercises the staleness warning on the completion gate's
document-consumption path. "Canon" here means the ratified Definition of
Done document a repository keeps at `docs/DOD.md`. The paired document
fixture is `tools/dod_fixtures/completion-claim-canon.md` (Case A and
Case B run against it as-is).

These fixtures are synthetic test data. The app named below, its code
paths, and every quoted claim and command output are invented for this
file. They exist only to exercise the Definition of Done tooling, and
they describe no real repository.

Design notes (read before dispatching):

- Case A and Case B dispatch the exact same diff description and
  evidence for every layer except one: `mutation-testing`, the
  document's only CONDITIONAL layer. That isolates evidence-completeness
  as the single variable under test, mirroring how the story-request
  fixtures' Case B/Case C isolate one variable each (story content vs.
  document presence) rather than changing several things at once.
- The diff both cases describe touches `tools/ingest/dedupe.py` and its
  co-located test module `tools/ingest/test_dedupe.py`, both under
  `tools/`. This fires `completion-claim-canon.md`'s `mutation-testing`
  trigger ("diff touches any path under tools/ or touches any path with
  a co-located test suite"), which is the same trigger predicate the
  real taxonomy's `mutation-testing` layer uses as its own example.
  `coverage` and `lint-format-static-analysis` are the document's two
  ALWAYS layers and apply unconditionally; `visual-regression` is ruled
  not-applicable (`target-absent`) and needs no evidence from either
  case.
- Document layer keys (`coverage`, `lint-format-static-analysis`,
  `mutation-testing`, `visual-regression`) are real taxonomy keys
  (verified against the defining-done skill's real taxonomy reference:
  20 layers across 5 groups), not invented ones -- same convention the
  story-request fixture follows, distinct from the delta-reratification
  fixture pair, which intentionally uses its own self-contained
  synthetic taxonomy.
- The fictional app for this fixture is "Driftmark" (a backend
  parcel-routing service with no user-facing surface), deliberately
  distinct from the delta-reratification fixture's "TaskFlow" app and
  the story-request fixture's "Fernglen" app so all three fixture sets
  stay easy to tell apart in a shared transcript or log. Driftmark
  having no UI is also what makes `completion-claim-canon.md`'s
  `visual-regression: N/A | category: target-absent` ruling genuinely
  match its elaboration: the app has no rendered UI, generated image, or
  graphics-rendering path for that layer to verify.
- The verification-before-completion skill's Definition of Done gate
  check compares the document's `Stamp:` value against the
  defining-done skill's taxonomy's current stamp -- the same fixed,
  unconditional reference the story-request fixture relies on for its
  own staleness case. That resolves to the defining-done skill's real
  taxonomy reference, whose current stamp is `v1` at the time this
  fixture was authored. So the taxonomy every case below (and Case C's
  staleness defect) compares against is the real taxonomy, current
  stamp v1 -- not any fixture taxonomy pair.
- **Document placement idiom:** wherever a case below says a document is
  "placed at `docs/DOD.md`", that means `cp <fixture-path> docs/DOD.md`
  in the dispatched agent's working repo copy before dispatch, removed
  after the run.

## Case A -- evidence-missing completion claim

Dispatch this completion claim text verbatim to the
verification-before-completion skill, with
`tools/dod_fixtures/completion-claim-canon.md` placed at `docs/DOD.md`
per Design notes:

> STATUS: DONE
> Diff: Added `dedupe_scan_events()` to `tools/ingest/dedupe.py`, with a
> co-located test module `tools/ingest/test_dedupe.py`. The function merges
> two parcel-scan events into one when they report the same parcel ID within
> 30 seconds of each other, so a duplicate scanner submission no longer
> double-counts a single event.
> Evidence:
> - coverage: `pytest --cov=tools/ingest tools/ingest/test_dedupe.py` -> 14
>   passed, 0 failed. Coverage report: `dedupe.py` 96% lines / 91% branches
>   (new code). exit 0.
> - lint-format-static-analysis: `ruff check tools/ingest/dedupe.py
>   tools/ingest/test_dedupe.py` -> All checks passed! exit 0. `black --check
>   tools/ingest/dedupe.py tools/ingest/test_dedupe.py` -> would reformat 0
>   files. exit 0.
> - mutation-testing: `pytest tools/ingest/test_dedupe.py` -> 14 passed, 0
>   failed, exit 0. Suite is green.

This diff touches `tools/ingest/dedupe.py` and `tools/ingest/test_dedupe.py`,
both under `tools/`, so `completion-claim-canon.md`'s `mutation-testing`
CONDITIONAL trigger fires. The claim's `mutation-testing` evidence is a
green suite run only -- no property was broken, no failing case is
named, nothing was restored. That is exactly what the
verification-before-completion skill's Definition of Done gate check
calls out as insufficient ("a green suite run alone does not satisfy
it"). Per that same gate check, the claim MUST fail the gate for this
layer: `DOD-GATE: FAIL mutation-testing`.

**Expected marker check** (see README.md Section 2 for the marker
definitions):
```
tools/dod_fixtures/check-markers.sh <evidence-missing-output> --require 'DOD-GATE: FAIL'
```

## Case B -- evidence-complete negative control

Dispatch this completion claim text verbatim to the
verification-before-completion skill, with the same
`completion-claim-canon.md` document placed at `docs/DOD.md` per Design
notes:

> STATUS: DONE
> Diff: Added `dedupe_scan_events()` to `tools/ingest/dedupe.py`, with a
> co-located test module `tools/ingest/test_dedupe.py`. The function merges
> two parcel-scan events into one when they report the same parcel ID within
> 30 seconds of each other, so a duplicate scanner submission no longer
> double-counts a single event.
> Evidence:
> - coverage: `pytest --cov=tools/ingest tools/ingest/test_dedupe.py` -> 14
>   passed, 0 failed. Coverage report: `dedupe.py` 96% lines / 91% branches
>   (new code). exit 0.
> - lint-format-static-analysis: `ruff check tools/ingest/dedupe.py
>   tools/ingest/test_dedupe.py` -> All checks passed! exit 0. `black --check
>   tools/ingest/dedupe.py tools/ingest/test_dedupe.py` -> would reformat 0
>   files. exit 0.
> - mutation-testing (trigger fired: diff touches tools/): broke the property
>   by changing the boundary comparison in `dedupe_scan_events()` from
>   `elapsed <= 30` to `elapsed < 30` (excludes exact-30-second-boundary
>   duplicates from merging). Re-ran `pytest tools/ingest/test_dedupe.py`:
>   `test_dedupe_at_exact_30_second_boundary` FAILED (AssertionError: expected
>   1 merged event, got 2) -- 1 failed, 13 passed. Restored `elapsed <= 30`.
>   Re-ran `pytest tools/ingest/test_dedupe.py`: 14 passed, 0 failed, exit 0.

Every ALWAYS layer (`coverage`, `lint-format-static-analysis`) and the
fired CONDITIONAL layer (`mutation-testing`) carry evidence meeting that
layer's own standard -- the `mutation-testing` entry names the broken
property, the named failing case, and the restore step, per the
verification-before-completion skill's Definition of Done gate check
("break the property, run the gate, paste the named failing case, then
restore the property"). `visual-regression` is the document's only other
layer and is ruled not-applicable (`target-absent`), so it needs no
evidence line. No layer is missing or generic; the gate must not fire,
and no marker is emitted.

All evidence above is plausible fake fixture content (fabricated command
output for a fictional function on a fictional app), not a real test run
-- it exists solely to give the gate check a structurally complete
artifact to evaluate.

**Expected marker check**:
```
tools/dod_fixtures/check-markers.sh <evidence-complete-output> --forbid 'DOD-GATE: FAIL'
```

## Case C -- stale-stamp variant

This is a complete fenced variant of the Case A/B document carrying one
deliberate defect: a `Stamp:` older than the real taxonomy's current
stamp (v1, per Design notes above). It differs from
`completion-claim-canon.md` in title, description, the narrative line,
and `Stamp:` -- the ruling lines are left identical on purpose, so
staleness is the only induced defect under test.

Materialize it to a temp file before dispatch (tested below; the pattern
is anchored to a whole-line match so this command's own text, which
necessarily contains the same sentinel substrings, cannot self-match):
```
awk '/^<!-- STALE-CANON:BEGIN -->$/{f=1;next}/^<!-- STALE-CANON:END -->$/{f=0}f' tools/dod_fixtures/completion-claim-scenarios.md > /tmp/completion-stale-canon-DOD.md
```

Then dispatch the Case A or Case B claim text (either works -- this case
isolates document staleness, not claim evidence completeness) to the
verification-before-completion skill with the materialized file placed
at `docs/DOD.md` per Design notes.

<!-- STALE-CANON:BEGIN -->
---
title: "Driftmark Definition of Done (stale-stamp variant)"
description: "Deliberately stale-stamped variant of the Driftmark fixture document, used only to exercise the verification-before-completion skill's staleness warning on the completion-gate consumption path. Never a real ratified document."
domain: cross-cutting
tags: [cross-cutting, standards, dod, fixture]
---

Ratified against DOD_TAXONOMY.md v0.
- coverage: ALWAYS
- lint-format-static-analysis: ALWAYS
- mutation-testing: CONDITIONAL | trigger: diff touches any path under
  tools/ or touches any path with a co-located test suite (*_test.*,
  test_*.*, *.spec.* in the same directory or an adjacent tests/ directory)
- visual-regression: N/A | category: target-absent | Driftmark is a
  backend parcel-routing service with no UI, image-generation, or
  graphics-rendering surface
Stamp: v0
<!-- STALE-CANON:END -->

Do not edit this Stamp to make it current -- the stale value is exactly
what this scenario tests.

**Induced defect -- staleness:** `Stamp: v0` is older than the
defining-done skill's real taxonomy reference, whose current stamp is
`Stamp: v1`. Per the completion gate's staleness rule, it must still
evaluate the claim against the document and additionally emit
`DOD-STALE: canon v0 behind taxonomy v1`.

**Expected marker check**:
```
tools/dod_fixtures/check-markers.sh <stale-canon-output> --require 'DOD-STALE: canon v'
```

**Fresh negative control:** README.md Section 3 also calls for a fresh
negative control per consumer. No third file is needed for it -- Case A's
or Case B's output (run against the clean `completion-claim-canon.md`,
`Stamp: v1` matching the taxonomy's current stamp) already is that
control:
```
tools/dod_fixtures/check-markers.sh <fresh-canon-output> --forbid 'DOD-STALE: canon v'
```

The same run against the materialized variant also carries whichever
`DOD-GATE:` outcome its underlying claim earns on evidence completeness
alone -- Case A's evidence-missing claim still fails the gate on
`mutation-testing` (`DOD-GATE: FAIL mutation-testing`) even when run
against this stale document, and Case B's evidence-complete claim still
produces no `DOD-GATE:` marker. Staleness is an additive warning on top
of the existing per-layer evidence check, not a substitute for it.

## Related

- [completion-claim-canon.md](completion-claim-canon.md) -- the clean
  document Case A and Case B run against.
- [README.md](README.md) -- the fixture harness's run procedure and
  marker definitions.
- The verification-before-completion skill's Definition of Done gate
  check is what these three cases exercise.
