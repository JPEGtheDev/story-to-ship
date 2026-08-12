# DoD fixture harness

## 1. Purpose

This directory holds the fixture-proof harness for the Definition of Done
(DoD) canon skill chain built under issue #66. Four todos in that plan
(T4a, T4b, T6, T8 -- see `plan.md`'s Review-closure rule) cap their Stage
1/2 review at `DONE_WITH_CONCERNS` until an observed fixture run proves
their behavior end to end. `check-markers.sh` is the oracle that turns a
captured fixture-run transcript into a pass/fail verdict: it greps a
run's output file for the pinned marker strings defined below and asserts
each one is present (a positive assertion) or absent (a negative
assertion). T12a-c's fixture-run dispatches are the todos that actually
exercise this harness and use its PASS/FAIL verdict to upgrade T4b, T6,
and T8 from `DONE_WITH_CONCERNS` to `DONE`. T4a upgrades the same way but
rides on T12a's FS4 fixture transcript rather than a dedicated fixture of
its own (plan.md's AC mapping table: FS1's owning todo is T4a, fixture
"none -- covered by FS4 fixture's transcript"), so T12a's PASS verdict
upgrades both T4a and T4b together.

## 2. Oracle definitions

The four marker strings below are quoted verbatim from
`skills/defining-done/references/DOD_TEMPLATE.md` Section C ("Consumer
notes"), which is their canonical source. That file is authoritative if
this README and it ever disagree.

- `DOD-VIOLATION: <layer>` -- the generator's refusal marker, emitted when
  a story omits an ALWAYS layer with no category-tagged N/A line.
- `DOD-GATE: FAIL <layer>` -- the completion gate's failure marker,
  emitted when a completion claim lacks evidence for an ALWAYS layer or a
  CONDITIONAL layer whose trigger fired.
- `DOD-HASH: MISMATCH` -- emitted by either consumer when the recomputed
  content-hash does not match the canon's `Content-hash:` footer. This is
  a warn-and-consume oracle: the canon is still read and used, so this
  marker signals a trust flag, not a parse failure.
- `DOD-STALE: canon v<N> behind taxonomy v<M>` -- emitted by either
  consumer when the canon's `Stamp: vN` is older than
  `DOD_TAXONOMY.md`'s current stamp. The canon is still consumed:
  staleness is a currency warning, not a refusal trigger.

`<layer>`, `<N>`, and `<M>` are parameterized tails (a layer key, or
version numbers). `check-markers.sh` asserts on the fixed prefix up to
that parameter, not the full parameterized string:

| Marker | Fixed-prefix literal to assert |
|---|---|
| `DOD-VIOLATION: <layer>` | `DOD-VIOLATION:` |
| `DOD-GATE: FAIL <layer>` | `DOD-GATE: FAIL` |
| `DOD-HASH: MISMATCH` | `DOD-HASH: MISMATCH` (no parameter, use in full) |
| `DOD-STALE: canon v<N> behind taxonomy v<M>` | `DOD-STALE: canon v` |

## 3. Run procedure

Fixture *input* files (taxonomy pairs, canon files, story requests,
completion claims) are created by T11b (FS4), T11c (FS2/FS5), and T11d
(FS3) -- they do not exist yet as of T11a and this README does not name
their exact paths. The procedure below is the shape T12a-c follow once
those inputs land:

1. Dispatch the fixture scenario (e.g. run `user-story-generator` against
   an FS2 fixture story request, or `verification-before-completion`
   against an FS3 fixture completion claim), capturing its full output to
   a file -- e.g. `tools/dod_fixtures/runs/fs2-violating.out` (the `runs/`
   directory is created at dispatch time; it is not a tracked deliverable
   of any T11 todo).
2. Invoke `check-markers.sh` against that captured output with the
   `--require`/`--forbid` set appropriate to the scenario. Concrete
   examples, one positive and one negative case per FS this harness
   directly proves:

   FS2 (canon-derived story DoD + refusal, created by T11c):
   ```
   tools/dod_fixtures/check-markers.sh <fs2-violating-story-output> --require 'DOD-VIOLATION:'
   tools/dod_fixtures/check-markers.sh <fs2-compliant-story-output> --forbid 'DOD-VIOLATION:'
   ```

   FS3 (gate fail observable, created by T11d):
   ```
   tools/dod_fixtures/check-markers.sh <fs3-evidence-missing-output> --require 'DOD-GATE: FAIL'
   tools/dod_fixtures/check-markers.sh <fs3-evidence-complete-output> --forbid 'DOD-GATE: FAIL'
   ```

   FS5 (canon-less fallback, created by T11c): no canon exists for this
   scenario, so `DOD-VIOLATION:` must never fire -- the fallback case is a
   forbid-only assertion (there is no separate marker for "fallback
   statement shown"; that text is checked by reading the captured output,
   not by this harness):
   ```
   tools/dod_fixtures/check-markers.sh <fs5-no-canon-output> --forbid 'DOD-VIOLATION:'
   ```

   FS7 (staleness on read, created by T11c/T11d stale-stamp and
   tampered-hash variants): one run per consumer (generator, gate), each
   with a stale/tampered variant and a fresh/untampered negative control:
   ```
   tools/dod_fixtures/check-markers.sh <fs7-stale-stamp-output> --require 'DOD-STALE: canon v'
   tools/dod_fixtures/check-markers.sh <fs7-tampered-hash-output> --require 'DOD-HASH: MISMATCH'
   tools/dod_fixtures/check-markers.sh <fs7-fresh-untampered-output> --forbid 'DOD-STALE: canon v' --forbid 'DOD-HASH: MISMATCH'
   ```
3. A `RESULT: PASS (N/N)` line and exit code 0 from every invocation in a
   scenario is what upgrades that scenario's todo (T4b via T12a, T6 via
   T12b, T8 via T12c) from `DONE_WITH_CONCERNS` to `DONE`. Any `RESULT:
   FAIL` or nonzero exit is pasted into the review as-is; the todo stays
   capped.

## 4. Consent note

Fixture-run dispatches (T12a-c) are spend-bearing agent invocations, not
free static checks. The plan ratified for issue #66 covers exactly ONE
run of each scenario (FS4 via T12a, FS2/FS5/FS7-generator via T12b,
FS3/FS7-gate via T12c). Any re-run -- to chase a flaky result, re-verify
after a later edit, or extend coverage -- requires fresh per-invocation
user consent before it is dispatched. This applies even if the original
run's PASS result is later doubted; re-running to double-check is still a
new spend-bearing invocation.
