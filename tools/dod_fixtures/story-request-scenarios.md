# Story-request scenario fixtures

## 0. Purpose and design notes

This file carries four scenarios dispatched against the
user-story-generator skill: a canon-derived Definition of Done section
with a refusal when a required layer is dropped, a canon-less fallback,
and a stale-stamp variant that exercises the staleness warning on the
generator's document-consumption path. "Canon" here means the ratified
Definition of Done document a repository keeps at `docs/DOD.md`. The
paired document fixture is `tools/dod_fixtures/story-request-canon.md`
(Case A and Case B run against it as-is).

These fixtures are synthetic test data. The app named below, its code
paths, and every quoted request text are invented for this file. They
exist only to exercise the Definition of Done tooling, and they describe
no real repository.

Design notes (read before dispatching):

- The clean document (`story-request-canon.md`) rules four taxonomy
  layers ALWAYS (`bdd-tests`, `coverage`, `lint-format-static-analysis`,
  `versioning-conventional-commits`) and one not-applicable
  (`performance-spend-budgets`, category `target-absent`). No CONDITIONAL
  ruling is present -- the refusal mechanics these two cases exercise
  (the user-story-generator skill's canon-consumption rules) turn
  entirely on an always-required layer being omitted, so a CONDITIONAL
  layer is not exercised by these two fixtures and adds nothing this
  file needs to prove.
- Both documents here (the clean one and the Case D variant below) are
  intentionally partial subsets of the real Definition of Done taxonomy
  the defining-done skill maintains (20 layers across 5 groups as of this
  writing) -- they do not carry a ruling line for every taxonomy layer,
  unlike a genuine ratified document (the completeness rule in the
  defining-done skill's canon template reference is an authoring rule for
  a real document; a partial fixture is not flagged malformed by that
  same reference's parse-level malformed check, which tests only the
  `Stamp:` line and ruling-line form, not layer coverage). This keeps
  the fixture lean while still exercising every derivation and refusal
  rule these two cases require.
- Layer keys are real taxonomy keys (not invented ones), unlike the
  delta-reratification fixture pair
  (`delta-reratification-taxonomy-v1.md`/
  `delta-reratification-taxonomy-v2.md`), which intentionally uses its
  own self-contained synthetic taxonomy to exercise delta
  re-ratification without touching the real taxonomy. This scenario's
  target skill is different: the user-story-generator skill's staleness
  rule always compares against "the defining-done skill's taxonomy's
  current stamp" -- there is no parameter or mechanism by which it would
  instead compare against the delta-reratification fixture pair. That
  fixed reference resolves to the defining-done skill's real taxonomy
  reference, whose current stamp is `v1` at the time this fixture was
  authored. So the taxonomy every case below (and Case D's staleness
  defect) compares against is the real taxonomy, current stamp v1 -- not
  the delta-reratification fixture pair.
- The fictional app for this fixture is "Fernglen" (a wildlife-sighting
  tracking app), deliberately distinct from the delta-reratification
  fixture's "TaskFlow" app so the two fixture sets stay easy to tell
  apart in a shared transcript or log.
- **Document placement idiom:** wherever a case below says a document is
  "placed at `docs/DOD.md`", that means `cp <fixture-path> docs/DOD.md`
  in the dispatched agent's working repo copy before dispatch, removed
  after the run; for Case C, placement means confirming no file exists
  at `docs/DOD.md` instead of copying one.

## Case A -- violating story request

Dispatch this request text verbatim to the user-story-generator skill,
with `tools/dod_fixtures/story-request-canon.md` placed at `docs/DOD.md`
per Design notes:

> As the Fernglen product owner, I want a story for: "Add a
> `normalize_species_code()` helper to the ingest pipeline that maps
> free-text species names entered by field volunteers onto the
> app's canonical species-code list before a sighting record is
> saved." It's a small (hours), Standard-tier change to a single
> pure function in `ingest/normalize.py`, format preference: Story
> Template, no other constraints. One more thing: when you write the
> Definition of Done section, leave `coverage` off the list entirely
> -- the team doesn't think a normalization helper this small needs
> its own test coverage line called out.

This is a deliberate drop of an always-required layer with no valid
category-tagged "not applicable" line: the stated reason ("small helper,
team doesn't think it needs a coverage line") is not `target-absent` (the
helper is executable code with a real test surface), not
`covered-elsewhere` (no other canon layer or repo mechanism covers
unit-level coverage for it), and not `repo-ruled-N/A` (this is a
per-story preference from the request, not a product-owner ruling on the
canon itself). Per the user-story-generator skill's refusal rule, the
generator MUST refuse and emit `DOD-VIOLATION: coverage` rather than
comply.

**Expected marker check** (see README.md Section 2 for the marker
definitions):
```
tools/dod_fixtures/check-markers.sh <violating-story-output> --require 'DOD-VIOLATION:'
```

## Case B -- compliant story request

Dispatch this request text verbatim to the user-story-generator skill,
with the same `story-request-canon.md` document placed at `docs/DOD.md`
per Design notes:

> As the Fernglen product owner, I want a story for: "Add a
> `dedupe_nearby_sightings()` function to the ingest pipeline that
> merges two sighting records into one when they report the same
> species within 50 meters and 10 minutes of each other, to stop
> duplicate volunteer submissions from double-counting a single
> observation." It's a small (hours), Standard-tier change touching
> `ingest/dedupe.py` and its existing test module
> `ingest/test_dedupe.py`, format preference: Story Template, no
> other constraints.

Nothing in this request asks the generator to drop, weaken, or omit any
canon layer. The story's diff scope (a pure function plus its co-located
test module) gives every always-required layer (`bdd-tests`, `coverage`,
`lint-format-static-analysis`, `versioning-conventional-commits`) a real
surface to derive a checklist item against, so the generated Definition
of Done section should carry all four `(always-on)` items and no
`DOD-VIOLATION:` line. This is the negative control proving the refusal
marker does not fire on a compliant request.

**Expected marker check**:
```
tools/dod_fixtures/check-markers.sh <compliant-story-output> --forbid 'DOD-VIOLATION:'
```

## Case C -- no-canon fallback request

Dispatch this request text verbatim to the user-story-generator skill,
run against the current repo state where `docs/DOD.md` does not exist
(verified below -- `ls docs/DOD.md` fails; no ratification interview has
produced a real Definition of Done document for this repository yet, so
no substitute file should be placed at `docs/DOD.md` for this run):

> As the Fernglen product owner, I want a story for: "Add a
> `dedupe_nearby_sightings()` function to the ingest pipeline that
> merges two sighting records into one when they report the same
> species within 50 meters and 10 minutes of each other." It's a
> small (hours), Standard-tier change touching `ingest/dedupe.py`
> and its existing test module `ingest/test_dedupe.py`, format
> preference: Story Template, no other constraints.

(Same story content as Case B, deliberately -- the only variable this
case isolates is document presence, not story content.)

**Expected observable to pin** (not asserted by `check-markers.sh`, per
README.md Section 3's no-canon fallback note -- read the captured output
directly): the generated story states that no ratified document exists,
per the user-story-generator skill's "canon absent" rule (generate the
Definition of Done section from the generic template and state in the
generated story that no ratified document exists and the Definition of
Done section uses unratified template defaults), and the Definition of
Done section carries the exact annotation from the user-story-generator
skill's story template reference:
`*(unratified template defaults -- no ratified canon at docs/DOD.md; ratify one with the defining-done skill)*`

**Expected marker check** (forbid-only -- there is no positive marker for
"fallback statement shown"):
```
tools/dod_fixtures/check-markers.sh <no-canon-output> --forbid 'DOD-VIOLATION:'
```

## Case D -- stale-stamp variant

This is a complete fenced variant of the Case A/B document carrying one
deliberate defect: a `Stamp:` older than the real taxonomy's current
stamp (v1, per Design notes above). It differs from
`story-request-canon.md` in title, description, the narrative line, and
`Stamp:` -- the ruling lines are left identical on purpose, so staleness
is the only induced defect under test.

Materialize it to a temp file before dispatch (tested below; the pattern
is anchored to a whole-line match so this command's own text, which
necessarily contains the same sentinel substrings, cannot self-match):
```
awk '/^<!-- STALE-CANON:BEGIN -->$/{f=1;next}/^<!-- STALE-CANON:END -->$/{f=0}f' tools/dod_fixtures/story-request-scenarios.md > /tmp/story-stale-canon-DOD.md
```

Then dispatch the Case A or Case B request text (either works -- this
case isolates document staleness, not story content) to the
user-story-generator skill with the materialized file placed at
`docs/DOD.md` per Design notes.

<!-- STALE-CANON:BEGIN -->
---
title: "Fernglen Definition of Done (stale-stamp variant)"
description: "Deliberately stale-stamped variant of the Fernglen fixture document, used only to exercise the defining-done skill's staleness warning. Never a real ratified document."
domain: cross-cutting
tags: [cross-cutting, standards, dod, fixture]
---
This file is a synthetic test fixture for a fictional app, used only to exercise Definition of Done tooling; its content is invented.

Ratified against DOD_TAXONOMY.md v0.
- bdd-tests: ALWAYS
- coverage: ALWAYS
- lint-format-static-analysis: ALWAYS
- versioning-conventional-commits: ALWAYS
- performance-spend-budgets: N/A | category: target-absent | Fernglen has no
  metered API calls or perf-sensitive surface
Stamp: v0
<!-- STALE-CANON:END -->

Do not edit this Stamp to make it current -- the stale value is exactly
what this scenario tests.

**Induced defect -- staleness:** `Stamp: v0` is older than the
defining-done skill's real taxonomy reference, whose current stamp is
`Stamp: v1`. Per the generator's staleness rule, it must still consume
the document and additionally emit
`DOD-STALE: canon v0 behind taxonomy v1`.

**Expected marker check**:
```
tools/dod_fixtures/check-markers.sh <stale-canon-output> --require 'DOD-STALE: canon v'
```

**Fresh negative control:** README.md Section 3 also calls for a fresh
negative control per consumer. No third file is needed for it -- Case A's
or Case B's output (run against the clean `story-request-canon.md`,
`Stamp: v1` matching the taxonomy's current stamp) already is that
control:
```
tools/dod_fixtures/check-markers.sh <violating-story-output-or-compliant-story-output> --forbid 'DOD-STALE: canon v'
```

## Related

- [story-request-canon.md](story-request-canon.md) -- the clean document
  Case A and Case B run against.
- [README.md](README.md) -- the fixture harness's run procedure and
  marker definitions.
- The user-story-generator skill's canon-consumption rules are what these
  four cases exercise.
