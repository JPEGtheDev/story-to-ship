# FS2/FS5 story-request fixtures (T11c, issue #66)

## 0. Purpose and design notes

This file carries the four run cases T12b dispatches against
`user-story-generator` to prove FS2 (canon-derived Definition of Done +
ALWAYS-layer refusal), FS5 (canon-less fallback), and the FS7/A14
staleness + hash-tamper warnings on the generator's consumption path. The
paired canon fixture is `tools/dod_fixtures/fs2-canon-DOD.md` (Case A and
Case B run against it as-is).

Design notes (read before dispatching):

- The clean canon (`fs2-canon-DOD.md`) rules four taxonomy layers ALWAYS
  (`bdd-tests`, `coverage`, `lint-format-static-analysis`,
  `versioning-conventional-commits`) and one N/A
  (`performance-spend-budgets`, category `target-absent`). No CONDITIONAL
  ruling is present -- FS2's refusal mechanics (`user-story-generator`
  SKILL.md, "DoD Canon Consumption") turn entirely on ALWAYS-layer
  omission, so a CONDITIONAL layer is not exercised by these two fixtures
  and adds nothing this file needs to prove.
- Both canons here (the clean one and the Case D variant below) are
  intentionally partial subsets of the real
  `skills/defining-done/references/DOD_TAXONOMY.md` (20 layers across 5
  groups as of this writing) -- they do not carry a ruling line for every
  taxonomy layer, unlike a genuine ratified canon (DOD_TEMPLATE.md
  Section A.3's completeness rule is an authoring rule for real canon; a
  partial fixture is not flagged malformed by the parse-level malformed
  check in DOD_TEMPLATE.md Section C, which tests only the `Stamp:` line,
  ruling-line-form, and `Content-hash:` line, not layer coverage). This
  keeps the fixture lean while still exercising every derivation and
  refusal rule these two FS cases require.
- Layer keys are real `DOD_TAXONOMY.md` Keys (not invented ones), unlike
  T11b's FS4 fixture pair, which intentionally uses its own self-contained
  synthetic taxonomy (`fs4-taxonomy-v1.md`/`fs4-taxonomy-v2.md`) to
  exercise delta re-ratification without touching the real taxonomy. FS2's
  target skill is different: `user-story-generator` SKILL.md's staleness
  bullet reads "the `defining-done` skill's taxonomy's current stamp"
  unconditionally -- there is no parameter or mechanism by which it would
  instead compare against T11b's fixture taxonomy pair. That fixed name
  resolves to `skills/defining-done/references/DOD_TAXONOMY.md`, whose
  line 10 reads `Stamp: v1` at the time this fixture was authored. So the
  taxonomy every case below (and Case D's staleness defect) compares
  against is the real `DOD_TAXONOMY.md`, current stamp v1 -- not the FS4
  fixture pair.
- The fictional app for this fixture is "Fernglen" (a wildlife-sighting
  tracking app), deliberately distinct from T11b's "TaskFlow" fixture so
  the two fixture sets stay easy to tell apart in a shared transcript or
  log.

## Case A -- violating story request (FS2 refusal)

Dispatch this request text verbatim to `user-story-generator`, with
`tools/dod_fixtures/fs2-canon-DOD.md` made readable at `docs/DOD.md` for
the run (per README.md Section 3's run procedure):

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

This is a deliberate ALWAYS-layer drop with no valid category-tagged N/A
line: the stated reason ("small helper, team doesn't think it needs a
coverage line") is not `target-absent` (the helper is executable code with
a real test surface), not `covered-elsewhere` (no other canon layer or
repo mechanism covers unit-level coverage for it), and not
`repo-ruled-N/A` (this is a per-story preference from the request, not a
product-owner canon-level ruling). Per SKILL.md's Refusal rule, the
generator MUST refuse and emit `DOD-VIOLATION: coverage` rather than
comply.

**Oracle** (README.md Section 3, FS2 positive case):
```
tools/dod_fixtures/check-markers.sh <fs2-violating-story-output> --require 'DOD-VIOLATION:'
```

## Case B -- compliant story request (FS2 negative control)

Dispatch this request text verbatim to `user-story-generator`, with the
same `fs2-canon-DOD.md` canon in place at `docs/DOD.md`:

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
test module) gives every ALWAYS layer (`bdd-tests`, `coverage`,
`lint-format-static-analysis`, `versioning-conventional-commits`) a real
surface to derive a checklist item against, so the generated Definition of
Done section should carry all four `(always-on)` items and no
`DOD-VIOLATION:` line. This is the negative control proving the refusal
marker does not fire on a compliant request.

**Oracle** (README.md Section 3, FS2 negative case):
```
tools/dod_fixtures/check-markers.sh <fs2-compliant-story-output> --forbid 'DOD-VIOLATION:'
```

## Case C -- no-canon fallback request (FS5)

Dispatch this request text verbatim to `user-story-generator`, run against
the current repo state where `docs/DOD.md` does not exist (verified below
-- `ls docs/DOD.md` fails; T13's dogfood interview has not yet produced a
real canon, so no substitute file should be placed at `docs/DOD.md` for
this run):

> As the Fernglen product owner, I want a story for: "Add a
> `dedupe_nearby_sightings()` function to the ingest pipeline that
> merges two sighting records into one when they report the same
> species within 50 meters and 10 minutes of each other." It's a
> small (hours), Standard-tier change touching `ingest/dedupe.py`
> and its existing test module `ingest/test_dedupe.py`, format
> preference: Story Template, no other constraints.

(Same story content as Case B, deliberately -- the only variable this case
isolates is canon presence, not story content.)

**Expected observable to pin** (not asserted by `check-markers.sh`, per
README.md Section 3's FS5 note -- read the captured output directly): the
generated story states that no ratified canon exists, per
`user-story-generator` SKILL.md's "Canon absent" bullet ("generate the
Definition of Done section from the generic template and state in the
generated story that no ratified canon exists and the Definition of Done
section uses unratified template defaults"), and the Definition of Done
section carries the exact annotation from
`skills/user-story-generator/references/STORY_TEMPLATE.md`:
`*(unratified template defaults -- no ratified canon at docs/DOD.md; ratify one with the defining-done skill)*`

**Oracle** (README.md Section 3, FS5 case -- forbid-only, no positive
marker exists for "fallback statement shown"):
```
tools/dod_fixtures/check-markers.sh <fs5-no-canon-output> --forbid 'DOD-VIOLATION:'
```

## Case D -- stale-stamp + tampered-hash variant (FS7/A14)

This is a complete fenced variant of the Case A/B canon carrying two
deliberate defects at once: a `Stamp:` older than the real taxonomy's
current stamp (v1, per Design notes above), and a `Content-hash:` value
that does not match the variant's own recomputed hash. It differs from
`fs2-canon-DOD.md` in title, description, the narrative line, `Stamp:`,
and `Content-hash:` -- the ruling lines are left identical on purpose, so
staleness and hash-tamper are the only two induced defects under test.

Materialize it to a temp file before dispatch (tested below; the pattern
is anchored to a whole-line match so this command's own text, which
necessarily contains the same sentinel substrings, cannot self-match):
```
awk '/^<!-- FS7-VARIANT-CANON:BEGIN -->$/{f=1;next}/^<!-- FS7-VARIANT-CANON:END -->$/{f=0}f' tools/dod_fixtures/fs2-fs5-story-requests.md > /tmp/fs7-variant-canon-DOD.md
```

Then dispatch the Case A or Case B request text (either works -- this case
isolates canon staleness/tamper, not story content) to
`user-story-generator` with the materialized file made readable at
`docs/DOD.md` for the run.

<!-- FS7-VARIANT-CANON:BEGIN -->
---
title: "Fernglen Definition of Done (FS2/FS5 fixture, FS7 stale+tampered variant)"
description: "Deliberately stale-stamped and hash-tampered variant of the Fernglen fixture canon, used only to exercise the defining-done skill's FS7 staleness warning and A14 hash-mismatch warn-and-consume path (issue #66). Never a real ratified canon."
domain: cross-cutting
tags: [cross-cutting, standards, dod, fixture]
related:
  - "../../docs/INDEX.md"
---

Ratified against DOD_TAXONOMY.md v0.
- bdd-tests: ALWAYS
- coverage: ALWAYS
- lint-format-static-analysis: ALWAYS
- versioning-conventional-commits: ALWAYS
- performance-spend-budgets: N/A | category: target-absent | Fernglen has no
  metered API calls or perf-sensitive surface
Stamp: v0
Content-hash: sha256:6e265fc3ab3eca551755164e85121dd7d4cda23d0bd95623f7df69be566caeb3
<!-- FS7-VARIANT-CANON:END -->

**Defect 1 -- staleness:** `Stamp: v0` is older than
`skills/defining-done/references/DOD_TAXONOMY.md`'s current `Stamp: v1`
(line 10 of that file). Per SKILL.md's Staleness bullet, the generator
must still consume the canon and additionally emit
`DOD-STALE: canon v0 behind taxonomy v1`.

**Defect 2 -- hash tamper:** the embedded `Content-hash:` value above
(`sha256:6e265fc3ab3eca551755164e85121dd7d4cda23d0bd95623f7df69be566caeb3`)
does not match the byte range's true recomputed digest
(`sha256:5e265fc3ab3eca551755164e85121dd7d4cda23d0bd95623f7df69be566caeb3`
-- see the recompute proof pasted in the T11c completion report; the two
values differ only in their first hex character, deliberately, so the
tamper is minimal and the value stays syntactically valid 64-lowercase-hex
throughout). Per SKILL.md's Hash check bullet, this is warn-and-consume:
the generator must still consume the canon and additionally emit
`DOD-HASH: MISMATCH`.

**Oracle** (README.md Section 3's FS7 pattern, folded into one combined
require since this is a single combined variant rather than two separate
stale-only/tampered-only files):
```
tools/dod_fixtures/check-markers.sh <fs7-stale-tampered-output> --require 'DOD-STALE: canon v' --require 'DOD-HASH: MISMATCH'
```

**FS7 fresh/untampered negative control:** README.md Section 3 also calls
for a fresh/untampered negative control per consumer. No third file is
needed for it -- Case A's or Case B's output (run against the clean,
untampered `fs2-canon-DOD.md`, `Stamp: v1` matching the taxonomy's current
stamp) already is that control:
```
tools/dod_fixtures/check-markers.sh <fs2-violating-story-output-or-fs2-compliant-story-output> --forbid 'DOD-STALE: canon v' --forbid 'DOD-HASH: MISMATCH'
```

## Related

- [fs2-canon-DOD.md](fs2-canon-DOD.md) -- the clean canon Case A and Case B
  run against.
- [README.md](README.md) -- the fixture harness's run procedure and
  oracle definitions.
- [../../skills/user-story-generator/SKILL.md](../../skills/user-story-generator/SKILL.md)
  -- the "DoD Canon Consumption" section these four cases exercise.
