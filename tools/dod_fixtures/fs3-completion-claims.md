# FS3 completion-claim fixtures (T11d, issue #66)

## 0. Purpose and design notes

This file carries the three run cases T12c dispatches against
`verification-before-completion` to prove FS3 (the DoD canon completion-gate
check: `DOD-GATE: FAIL <layer>` on missing/generic evidence, silent pass on
complete evidence) and the FS7/A14 staleness + hash-tamper warnings on the
completion-gate's consumption path. The paired canon fixture is
`tools/dod_fixtures/fs3-canon-DOD.md` (Case A and Case B run against it as-is).

Design notes (read before dispatching):

- Case A and Case B dispatch the exact same diff description and evidence for
  every layer except one: `mutation-testing`, the canon's only CONDITIONAL
  layer. That isolates evidence-completeness as the single variable under
  test, mirroring how T11c's Case B/Case C isolate one variable each (story
  content vs. canon presence) rather than changing several things at once.
- The diff both cases describe touches `tools/ingest/dedupe.py` and its
  co-located test module `tools/ingest/test_dedupe.py`, both under `tools/`.
  This fires `fs3-canon-DOD.md`'s `mutation-testing` trigger ("diff touches
  any path under tools/ or touches any path with a co-located test suite"),
  which is the same trigger predicate DOD_TAXONOMY.md's `mutation-testing`
  layer uses as its own example and the one the T1 falsification walkthrough
  (plan.md Link 2) modeled. `coverage` and `lint-format-static-analysis` are
  the canon's two ALWAYS layers and apply unconditionally; `visual-regression`
  is ruled N/A (`target-absent`) and needs no evidence from either case.
- Canon layer keys (`coverage`, `lint-format-static-analysis`,
  `mutation-testing`, `visual-regression`) are real `DOD_TAXONOMY.md` Keys
  (verified: `grep -c '^\*\*Key:\*\*' skills/defining-done/references/DOD_TAXONOMY.md`
  = 20 across `grep -c '^## '` = 5 groups), not invented ones -- same
  convention T11c's FS2/FS5 fixture follows, distinct from T11b's FS4 fixture
  pair, which intentionally uses its own self-contained synthetic taxonomy.
- The fictional app for this fixture is "Driftmark" (a backend parcel-routing
  service with no user-facing surface), deliberately distinct from T11b's
  "TaskFlow" and T11c's "Fernglen" fixtures so all three fixture sets stay
  easy to tell apart in a shared transcript or log. Driftmark having no UI is
  also what makes `fs3-canon-DOD.md`'s `visual-regression: N/A |
  category: target-absent` ruling genuinely match its elaboration: the app
  has no rendered UI, generated image, or graphics-rendering path for that
  layer to verify.
- `verification-before-completion` SKILL.md's "New Gates: DoD Canon Check on
  Completion Claims" section reads "Compare the canon's `Stamp:` value
  against the `defining-done` skill's taxonomy's current stamp" -- the same
  fixed, unconditional reference T11c's FS2/FS5 fixture relies on for its own
  staleness case. That resolves to the real
  `skills/defining-done/references/DOD_TAXONOMY.md`, whose line 10 reads
  `Stamp: v1` at the time this fixture was authored. So the taxonomy every
  case below (and Case C's staleness defect) compares against is the real
  `DOD_TAXONOMY.md`, current stamp v1 -- not any fixture taxonomy pair.
- **Canon placement idiom:** wherever a case below says a canon file is
  "placed at `docs/DOD.md`", that means `cp <fixture-path> docs/DOD.md` in
  the dispatched agent's working repo copy before dispatch, removed after the
  run.

## Case A -- evidence-missing completion claim (FS3 gate FAIL)

Dispatch this completion claim text verbatim to
`verification-before-completion`, with `tools/dod_fixtures/fs3-canon-DOD.md`
placed at `docs/DOD.md` per Design notes:

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
both under `tools/`, so `fs3-canon-DOD.md`'s `mutation-testing` CONDITIONAL
trigger fires. The claim's `mutation-testing` evidence is a green suite run
only -- no property was broken, no failing case is named, nothing was
restored. That is exactly the substitute DOD_TEMPLATE.md Section C's
canonical example calls out as insufficient ("a green suite run alone is NOT
evidence"). Per `verification-before-completion` SKILL.md's "New Gates: DoD
Canon Check on Completion Claims" gate check, the claim MUST fail the gate
for this layer: `DOD-GATE: FAIL mutation-testing`.

**Oracle** (README.md Section 3, FS3 positive case):
```
tools/dod_fixtures/check-markers.sh <fs3-evidence-missing-output> --require 'DOD-GATE: FAIL'
```

## Case B -- evidence-complete negative control (FS3 gate PASS)

Dispatch this completion claim text verbatim to
`verification-before-completion`, with the same `fs3-canon-DOD.md` canon
placed at `docs/DOD.md` per Design notes:

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

Every ALWAYS layer (`coverage`, `lint-format-static-analysis`) and the fired
CONDITIONAL layer (`mutation-testing`) carry evidence meeting that layer's
own standard -- the `mutation-testing` entry names the broken property, the
named failing case, and the restore step, per DOD_TEMPLATE.md Section C's
canonical example. `visual-regression` is the canon's only other layer and is
ruled N/A (`target-absent`), so it needs no evidence line. No layer is
missing or generic; the gate must not fire, and no marker is emitted.

All evidence above is plausible fake fixture content (fabricated command
output for a fictional function on a fictional app), not a real test run --
it exists solely to give the gate check a structurally complete artifact to
evaluate.

**Oracle** (README.md Section 3, FS3 negative case):
```
tools/dod_fixtures/check-markers.sh <fs3-evidence-complete-output> --forbid 'DOD-GATE: FAIL'
```

## Case C -- stale-stamp + tampered-hash variant (FS7/A14)

This is a complete fenced variant of the Case A/B canon carrying two
deliberate defects at once: a `Stamp:` older than the real taxonomy's current
stamp (v1, per Design notes above), and a `Content-hash:` value that does not
match the variant's own recomputed hash. It differs from `fs3-canon-DOD.md`
in title, description, the narrative line, `Stamp:`, and `Content-hash:` --
the ruling lines are left identical on purpose, so staleness and hash-tamper
are the only two induced defects under test.

Materialize it to a temp file before dispatch (tested below; the pattern is
anchored to a whole-line match so this command's own text, which necessarily
contains the same sentinel substrings, cannot self-match):
```
awk '/^<!-- FS3-VARIANT-CANON:BEGIN -->$/{f=1;next}/^<!-- FS3-VARIANT-CANON:END -->$/{f=0}f' tools/dod_fixtures/fs3-completion-claims.md > /tmp/fs3-variant-canon-DOD.md
```

Then dispatch the Case A or Case B claim text (either works -- this case
isolates canon staleness/tamper, not claim evidence completeness) to
`verification-before-completion` with the materialized file placed at
`docs/DOD.md` per Design notes.

<!-- FS3-VARIANT-CANON:BEGIN -->
---
title: "Driftmark Definition of Done (FS3 fixture, FS7 stale+tampered variant)"
description: "Deliberately stale-stamped and hash-tampered variant of the Driftmark fixture canon, used only to exercise the verification-before-completion skill's FS7 staleness warning and A14 hash-mismatch warn-and-consume path on the completion-gate consumption path (issue #66). Never a real ratified canon."
domain: cross-cutting
tags: [cross-cutting, standards, dod, fixture]
related:
  - "../../docs/INDEX.md"
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
Content-hash: sha256:d140f9695e0e88cc043a78952b603c54affbf70c1c16ccd38146f601c0647d56
<!-- FS3-VARIANT-CANON:END -->

**Defect 1 -- staleness:** `Stamp: v0` is older than
`skills/defining-done/references/DOD_TAXONOMY.md`'s current `Stamp: v1`
(line 10 of that file). Per SKILL.md's staleness bullet, the completion gate
must still evaluate the claim against the canon and additionally emit
`DOD-STALE: canon v0 behind taxonomy v1`.

**Defect 2 -- hash tamper:** the embedded `Content-hash:` value above
(`sha256:d140f9695e0e88cc043a78952b603c54affbf70c1c16ccd38146f601c0647d56`)
does not match the byte range's true recomputed digest
(`sha256:c140f9695e0e88cc043a78952b603c54affbf70c1c16ccd38146f601c0647d56`
-- see the recompute proof pasted in the T11d completion report; the two
values differ only in their first hex character, deliberately, so the tamper
is minimal and the value stays syntactically valid 64-lowercase-hex
throughout). Per SKILL.md's hash-check bullet, this is warn-and-consume: the
gate must still evaluate the claim against the canon and additionally emit
`DOD-HASH: MISMATCH`.

**Oracle** (README.md Section 3's FS7 pattern, folded into one combined
require since this is a single combined variant rather than two separate
stale-only/tampered-only files):
```
tools/dod_fixtures/check-markers.sh <fs7-stale-tampered-output> --require 'DOD-STALE: canon v' --require 'DOD-HASH: MISMATCH'
```

**FS7 fresh/untampered negative control:** README.md Section 3 also calls for
a fresh/untampered negative control per consumer. No third file is needed for
it -- Case A's or Case B's output (run against the clean, untampered
`fs3-canon-DOD.md`, `Stamp: v1` matching the taxonomy's current stamp)
already is that control:
```
tools/dod_fixtures/check-markers.sh <fs7-fresh-untampered-output> --forbid 'DOD-STALE: canon v' --forbid 'DOD-HASH: MISMATCH'
```

The same run against the materialized variant also carries whichever
`DOD-GATE:` outcome its underlying claim earns on evidence completeness alone
-- Case A's evidence-missing claim still fails the gate on `mutation-testing`
(`DOD-GATE: FAIL mutation-testing`) even when run against this stale/tampered
canon, and Case B's evidence-complete claim still produces no `DOD-GATE:`
marker. Staleness and hash-tamper are additive warnings on top of the
existing per-layer evidence check, not a substitute for it.

## Related

- [fs3-canon-DOD.md](fs3-canon-DOD.md) -- the clean canon Case A and Case B
  run against.
- [README.md](README.md) -- the fixture harness's run procedure and oracle
  definitions.
- [../../skills/verification-before-completion/SKILL.md](../../skills/verification-before-completion/SKILL.md)
  -- the "New Gates: DoD Canon Check on Completion Claims" section these
  three cases exercise.
