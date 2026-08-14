# defining-done (#66) -- session plan

Discovery (Three Amigos Ceremony 1) ran 2026-08-11: Business, Developer, Tester amigos
all returned findings (verdictless per ceremony definition). Feature Specification
below synthesized from Business + Tester findings; Developer findings recorded under
Implementation Notes. Open questions surfaced to the product owner before Refinement.

## Feature Specification

A product owner can run a prose interview that walks every verification layer in a
maintained taxonomy, group by group, and rule each layer for their repo: always
required, conditional with an objectively checkable trigger, or not applicable with a
reason. No ruling is ever pre-filled. The interview ends with one ratification pass
over the full result; only then is the repo's Definition of Done canon written into
the repo's documentation, stamped with the taxonomy version it was ratified against.

From then on:
- A story generated through the repo's story machinery derives its Definition of Done
  section from that canon. An always-required layer can be omitted only with an
  explicit, category-constrained not-applicable line; a story omitting one without it
  is refused/flagged (observably, not silently).
- A completion claim made through the repo's completion gate is checked against the
  canon's always-required layers and any conditional layers whose trigger fires
  against the change, each needing evidence or a category-constrained exception.
- When the taxonomy gains or changes layers after ratification, re-running the
  interview asks ONLY about the delta and leaves every prior ruling untouched;
  staleness is surfaced, never silent.
- New projects get the interview as a named step of project inception; existing repos
  invoke it directly.
- The repo's own canon is produced by actually running the interview with the product
  owner (real use in this repo) -- a real artifact, not a demonstration fixture.

Behavioral acceptance criteria (numbered, synthesized from Business AC-B1..B5 +
Tester verifiability findings):
1. Given a repo with no canon, when the owner runs the interview, then every taxonomy
   layer is presented for ruling and no ruling is filled by default.
2. Given a canon exists, when a story is generated, then its DoD section derives from
   the canon (not the generic hardcoded checklist), and an always-on layer omitted
   without a valid category-tagged N/A line causes an observable refusal/flag
   (violation case demonstrated, not just the compliant case).
3. Given a canon exists, when a completion claim omits an always-on layer's evidence,
   then the claim fails the gate observably (failing case demonstrated).
4. Given the taxonomy version advances, when the owner re-invokes the interview, then
   only new/changed layers are elicited and prior rulings survive byte-untouched
   except the stamp (fixture-proven).
5. Given no canon exists, when a story is generated, then the generator falls back to
   its current template and says so in the story.
6. Given the interview is abandoned before the final ratification pass, then no canon
   file is written or modified (atomic write at ratification only). [assumption A1]
7. Given a canon exists but its stamp is older than the current taxonomy, when the
   generator or completion gate reads it, then the staleness is noted in their output
   rather than silently consumed. [assumption A2]

Out of scope: CI enforcement of DoD sections; retrofitting closed issues; standing up
any layer's tooling; the sprint-engine stories (#34, #65); three-amigos/writing-plans
consumption of the canon (noted as follow-on candidates); repo-level taxonomy
extensions (owner proposals for new layers go to the central taxonomy, not per-repo
forks) [assumption A3].

Disclosed limits (carried from the issue + Discovery): binds only stories authored
through the skill machinery -- direct issue edits and skill-skipping sessions are not
caught (mechanical CI enforcement is the declined follow-on); interview QUALITY and
taxonomy external completeness are not tested by any AC (silent areas named by the
Tester); conditional-trigger evaluation correctness is Stage 1 reviewer judgment with
no mechanical detector.

## Implementation Notes (Developer amigo findings -- inputs to todo planning)

Verified edit-surface facts (spot-checked by orchestrator, this session):
- user-story-generator/SKILL.md:30 carries a SECOND premium-request instance (gate
  item 6 "Premium request estimate based on complexity") beyond the "Always include"
  block; the "All 9 met" gate count goes stale when it is removed. AC10 implementation
  must be driven by an unscoped repo-wide sweep, not the issue's named-locations list.
- user-story-generator/references/STORY_TEMPLATES.md (PLURAL, unreferenced by
  SKILL.md) contains 4 more hardcoded Definition of Done sections (5 grep hits) --
  scope ruling needed (dead file vs in-scope).
- 0 of 33 skills carry a version: frontmatter field; writing-skills' anatomy check
  does not require one. The issue DoD's "frontmatter versions bumped" item describes a
  mechanism with no codebase precedent -- ruling needed.
- documentation/SKILL.md:12 Iron Law caps every docs/ file at 800 tokens with YAML
  frontmatter + Related section; a 19-layer DOD.md plausibly exceeds it -- ruling
  needed (exception vs split into docs/dod/<layer> files vs index+detail shape).
- docs/ does not exist yet; documentation skill already requires INDEX.md updates for
  every new docs file (its Step 3 item 10) -- AC8 rides existing machinery.
- greenfield-discovery has no natural inception slot; phases are domain-modeling
  steps. Insertion point decision: recommended at the Downstream Contract handoff
  (after Domain Model), so the canon exists before architecture/bootstrap stories are
  generated. [assumption A4]
- verification-before-completion already has two precedent "New Gates" sections whose
  shape AC6/AC7 can follow; AC7's bar is that skill's own Gate-Can-Fail rule.
- Fallback path: STORY_TEMPLATE.md's hardcoded DoD (85% coverage etc.) remains the
  ungoverned default for canon-less repos; recommended: soften the fallback header to
  name itself unratified-defaults and point at defining-done. [assumption A5]
- Non-greenfield first invocation has no systemic trigger (no bootstrap On Start row);
  manual invocation is the v1 design consistent with the Gate 1 exception; the
  generated docs/INDEX.md entry is the standing pointer. [assumption A6]

Tester structural findings (fixture design constraints):
- AC2/AC4/AC6 fixtures exercise SKILLS (prose driving agents), not programs: pass/fail
  must be signal-presence oracles, not byte-exact assertions. Oracles must be pinned
  in the plan: the generator refusal emits a literal marker line (exact string fixed
  in the plan todo), the gate failure emits a literal FAIL line; fixtures assert
  marker presence. LLM-dispatching fixtures are spend-bearing and non-deterministic:
  they run as documented manually-runnable scripts, NOT CI (ruling needed on standing
  vs one-shot).
- AC2 rules (a)/(b) currently closeable on textual review alone -- violates
  verification-before-completion's own behavioral-evidence bar; the AC0 walkthrough +
  an added no-default-fill probe inside the AC3 fixture covers this.
- Hand-edited canon with intact stamp is invisible to all ACs -- add content-hash
  footer at ratification; consumers warn on mismatch. [assumption A7 -- new minor AC]
- Malformed canon (bad stamp/structure): generator/gate treat as "present but
  unreadable" -> refuse with diagnostic, never silently fall back as if absent.
  [assumption A8 -- new minor AC]
- N/A rationale at canon level uses the SAME closed category list as story-level
  (target-absent / covered-elsewhere / repo-ruled-N/A) + optional free-text
  elaboration after the category tag. [assumption A9]
- Version stamp format: monotonic integer (v1, v2, ...) in both taxonomy and canon.
  [assumption A10]

## Product-owner rulings (2026-08-11, unblocking Refinement)

Q1 RULED: AC12 DEFERRED out of #66 -- the #65 retrofit runs as the first act of #65's
    own Discovery later. AC12 is struck from this plan's scope.
Q2 RULED: index + detail split -- docs/DOD.md stays under the documentation skill's
    800-token cap as the ruling index (one line per layer); longer rationale goes to
    docs/dod/<layer>.md detail files. No Iron Law exception.
Q3 RULED: version: frontmatter is an OLD ARTIFACT -- deliberately absent, historically
    harmful ("agents screwed up versioning"). The DoD checklist item is DROPPED, and
    the stale bump-version instructions in session-bootstrap (On Finish step 4) and
    self-evaluation (Step 6 item 2) are removed in this story (ruling-driven scope
    addition, disclosed).
Q4 RULED: standing fixtures -- AC3/AC5/AC7 fixture scripts live in the repo
    (tools/dod_fixtures/), documented and manually re-runnable with per-invocation
    spend consent; oracles are pinned literal marker lines.

Assumptions A1-A10 folded as defaults (vetoable at Refinement), plus:
A11: STORY_TEMPLATES.md (plural, unreferenced by SKILL.md) hits found by the unscoped
     sweeps are adjudicated as legacy-unreferenced content -- annotated as unratified
     legacy, not canon-derived, not deleted.
A12 (Refinement fold): canon detail files live at docs/dod/<taxonomy-group>/<layer>.md
     (domain=dod, subdomain=<taxonomy-group>) satisfying the documentation skill's
     domain/subdomain path + frontmatter rules; docs/DOD.md stays the flat
     cross-cutting index.
A13 (Refinement fold): re-elicitation escape hatch -- after 3 failed attempts to make
     a conditional trigger checkable, the skill offers the owner an explicit binary
     choice (rule it always, or N/A repo-ruled); no default, loop bounded.
A14 (Refinement fold): hash-mismatch is a THIRD distinct consumer oracle (separate
     from staleness and malformed): literal warning line "DOD-HASH: MISMATCH" from
     both consumers; canon still consumed (warn, not refuse -- tampering is a
     trust flag, not a parse failure).
A15 (Refinement fold): A1 (abandon-interview writes nothing) is proven statically by
     the skill's write-order design (nothing written before the single final write
     step), NOT by a dispatched fixture -- disclosed as a behavior claim without an
     observed-proof fixture. A8 (malformed-canon refusal) is the second such claim:
     specified in the skill text and consumer gate, with no fixture run exercising a
     structurally-broken canon. The Write Step's index-chain step (added by Signoff
     revision R2b) is the third: the skill writing the per-level docs/dod index
     chain live has not been exercised by any dispatched run (T12a's delta run had
     no detail files, so the step's precondition was false; the existing chain was
     backfilled by R2a's implementer, not written by the skill). All three are
     disclosed in the PR body. Write order at
     ratification: detail files -> the docs/dod per-level index chain -> docs/DOD.md
     -> docs/INDEX.md, so an interrupted write leaves no live canon (DOD.md absent =
     no canon; files under docs/dod/ without it are inert).

## Refinement verdicts (Ceremony 2, 2026-08-11)

Business: CONDITIONS (7) / Developer: CONDITIONS / Tester: CONDITIONS (7). No REJECT.
All conditions folded into the revised todos below: T4/T7/T11/T12 split per the file
cap; todo labels renumbered to the Feature Spec's own AC1-7 with an explicit mapping
table; A5 fallback-header edit given an owning todo (T7b); A7 hash oracle named in
T6/T8 + fixtured (A14); PASS-path negative controls added (T11c/T11d, T12b/T12c);
canon-less fallback proof added (T12b); gate-item renumbering made explicit (T7a);
docs/dod path taxonomy resolved (A12); T4 atomic-write order specified (A15);
escape hatch bounded (A13); T13 session-boundary risk flagged.

Review-closure rule (Tester condition, from verification-before-completion's own bar):
T4a/T4b/T6/T8 close at DONE_WITH_CONCERNS maximum until their fixture proofs run
(T12a-c); T12 completion upgrades them to DONE. Their Stage 1/2 reviews still run at
build time; the CONCERNS flag marks the pending behavioral evidence only.

## AC mapping table (todo labels use Feature Spec numbering)

| Feature Spec AC | Issue #66 AC | Owning todos |
|---|---|---|
| FS1 no-default elicitation | AC2 | T4a (fixture: none -- covered by FS4 fixture's transcript) |
| FS2 canon-derived story DoD + refusal | AC4+AC5 | T6, T12b |
| FS3 gate fail observable | AC6+AC7 | T8, T12c |
| FS4 delta re-ratification | AC3 | T4b, T12a |
| FS5 canon-less fallback | AC4 fallback clause | T6, T12b negative control |
| FS6 abandon writes nothing | (new, Discovery) | T4a design + A15 static proof |
| FS7 staleness on read | (new, Discovery) | T6, T8, T12b/c staleness inputs |
| taxonomy + template + docs | AC1, AC8 | T2, T3, T5 |
| greenfield + sweeps + cleanup | AC9, AC10, Q3 | T9, T7a-d, T10 |
| real-use ratification | AC11 | T13 |

## Todos (revised post-Refinement; labels use Feature Spec (FS) numbering)

Sequencing rule: T1 is the falsification gate -- STOP and redesign if any link fails.
Every todo runs the 2-stage review (skill .md files get skill-reviewer at Stage 2).
T4a/T4b/T6/T8 cap at DONE_WITH_CONCERNS until T12a-c upgrade them (see Review-closure
rule above). Estimate: 19 todos, 2 sessions; T13 needs the product owner LIVE --
flagged session-boundary risk: if the session ends before T13, it is the first item
of the next session with the owner present. Fixture runs are spend-bearing; this
plan's approval covers ONE run of each (T12a-c); future re-runs re-ask.

T1 (gate): Falsification walkthrough on paper -- carry MUTATION TESTING end to end:
    taxonomy entry -> interview ruling (conditional; trigger predicate "diff touches
    tools/ or scripts with test suites") -> DOD.md index line -> generated story DoD
    section -> completion-gate check. Paste walkthrough in this file; verdict
    CONCRETE-AT-EVERY-LINK or STOP. Files: plan.md only.
T2 (taxonomy): Create references/DOD_TAXONOMY.md (20 layers, per-layer what-it-
    verifies + example checkable triggers + group assignment, version stamp v1) and
    references/INDEX.md for the new skill. Files: 2 create.
T3 (template): Create references/DOD_TEMPLATE.md -- DOD.md index format (one line per
    layer: ruling enum + trigger predicate or N/A category tag from the closed list
    target-absent/covered-elsewhere/repo-ruled-N/A + optional elaboration), stamp
    line, content-hash footer spec, detail-file format at
    docs/dod/<taxonomy-group>/<layer>.md with domain=dod subdomain=<group>
    frontmatter (A12). Files: 1 create, 1 edit (INDEX.md row).
T4a (FS1/FS6 core interview): Create defining-done/SKILL.md -- group-by-group prose
    elicitation, no default rulings, checkability re-elicitation loop with A13
    bounded escape hatch (3 attempts -> owner picks always or repo-ruled-N/A), final
    ratification pass, then the single write step in A15 order (details -> DOD.md ->
    INDEX.md; nothing written before this step; mkdir docs as needed; frontmatter per
    documentation skill). Files: 1 create, 1 edit (INDEX.md row).
T4b (FS4 + A8/A14 write-side): Edit defining-done/SKILL.md -- re-ratification delta
    mode (stamp compare, delta-only elicitation, prior rulings byte-preserved,
    re-stamp), malformed-canon refusal on read, content-hash computation + footer
    stamping at write. Files: 1 edit.
T5 (docs): Create docs/INDEX.md cataloging DOD.md + dod/ detail tree, YAML
    frontmatter per documentation skill. Files: 1 create.
T6 (FS2/FS5/FS7 generator consumption): Edit user-story-generator/SKILL.md -- read
    docs/DOD.md at BEFORE PROCEEDING context load; derive story DoD section from
    canon; always-on omission needs closed-category N/A line; THREE consumer oracles:
    "DOD-VIOLATION: <layer>" on refusal, stale-canon warning line, "DOD-HASH:
    MISMATCH" warn-and-consume (A14); malformed-canon refusal; absent-canon fallback
    statement. Files: 1 edit.
T7-sweep (scope step): Run the unscoped repo-wide sweep (case-insensitive premium
    word-forms + tier vocabulary); paste command + full output; adjudicate every hit
    (tier-name vs pricing; A11 for STORY_TEMPLATES.md). Adjudicated output = scope
    for T7a-d. Files: none.
T7a: Edit user-story-generator/SKILL.md -- remove "Always include" premium bullet +
    gate item 6, renumber items 7-9 -> 6-8, fix the "All 9 met" count. Files: 1 edit.
T7b: Edit references/STORY_TEMPLATE.md -- remove Total Premium Requests field, tier
    vocabulary fix (Small|Standard|Advanced -> Economy|Standard|Premium), soften the
    hardcoded DoD fallback header to name itself unratified-defaults pointing at
    defining-done (A5). Files: 1 edit.
T7c: Edit user-story-estimation/SKILL.md -- fix the stale Related Skills line.
    Files: 1 edit.
T7d: Edit references/STORY_TEMPLATES.md -- A11 legacy annotation on its DoD sections
    (+ any adjudicated premium hits). Files: 1 edit.
T8 (FS3/FS7 gate consumption): Edit verification-before-completion/SKILL.md -- new
    gate section in the file's New Gates shape: canon check on completion claims
    (always-on + fired conditional triggers; Stage 1 reviewer evaluates triggers,
    recorded in review output), oracles "DOD-GATE: FAIL <layer>", staleness warning,
    "DOD-HASH: MISMATCH" (A14), malformed-canon refusal. Files: 1 edit.
T9 (greenfield): Edit greenfield-discovery/SKILL.md -- named Skill(defining-done)
    step at the Downstream Contract handoff (after Domain Model, before architecture
    stories). Files: 1 edit.
T10 (Q3 ruling): Remove stale bump-version bullets -- session-bootstrap/SKILL.md On
    Finish step 4, self-evaluation/SKILL.md Step 6 item 2 (steps stay, only the
    version bullets go; cross-references to step numbers unaffected -- verified by
    Refinement Developer). Files: 2 edits.
T11a (fixture harness): Create tools/dod_fixtures/README.md (run procedure, consent
    note, oracle definitions) + check script grepping the pinned markers (positive
    AND negative assertions). Files: 2 create.
T11b (FS4 fixtures): Create fixture taxonomy vN + vN+1 pair and ruled fixture
    DOD.md (synthetic, NOT derived from T13's real canon). Files: 3 create (1-file
    overage disclosed: the three inputs are one inseparable scenario).
T11c (FS2/FS5 fixtures): Create always-on fixture canon + two story requests
    (violating AND compliant -- the compliant one is the negative control proving
    DOD-VIOLATION does not fire; plus a no-canon fallback case and a stale-stamp +
    tampered-hash variant for FS7/A14). Files: 2 create.
T11d (FS3 fixtures): Create fixture canon + two completion claims (evidence-missing
    AND evidence-complete negative control; plus stale/tampered variants). Files: 2
    create.
T12a (FS4 proof): Dispatch fixture run -- observed delta-only re-elicitation, prior
    rulings byte-identical. Upgrades T4b. Files: none (evidence pasted).
T12b (FS2/FS5/FS7 proof): Dispatch fixture runs -- observed DOD-VIOLATION on the
    violating story, observed NO marker + canon-derived section on the compliant
    story, observed fallback statement with no canon, observed staleness + hash
    warnings on the variants. Upgrades T6. Files: none.
T12c (FS3 proof): Dispatch fixture runs -- observed DOD-GATE: FAIL on the missing-
    evidence claim, observed pass with no marker on the complete claim, observed
    staleness/hash warnings. Upgrades T8. Files: none.
T13 (real-use ratification, OWNER LIVE): Interview with the product owner -> this repo's real
    docs/DOD.md (+ detail files per A12), hash stamped; rulings + taxonomy gaps
    recorded. Files: docs/DOD.md + details (count depends on owner rulings; disclosed
    open-ended, index+details all land in docs/).

Post-todos: Signoff (Ceremony 5), then finishing-a-development-branch, PR with the
FS-AC-to-evidence mapping (AC12 struck per Q1).

## T1 Falsification Walkthrough (executed 2026-08-11, fresh-agent authored)

Method note: authored by a dispatched agent from plan.md's format specs alone (a fresh
agent able to write every link concretely IS the concreteness evidence). Illustrative
content (group name "Test-Suite Integrity", sample hash, example layers) is
UNRATIFIED -- it proves the format holds real-looking content; T2/T3/T13 author the
real thing.

### Link 1 -- DOD_TAXONOMY.md entry (written concretely)

    ### Mutation Testing
    **Group:** Test-Suite Integrity
    **Verifies:** that the tests covering the changed code actually detect a broken
    implementation -- not merely that the suite executes and reports pass.
    **Example checkable triggers:**
    - diff touches any path under tools/
    - diff touches any path with a co-located test suite (*_test.*, test_*.*,
      *.spec.* in same dir or adjacent tests/)
    **Version:** v1

### Link 2 -- interview exchange (written concretely)

    SKILL: Layer "Mutation Testing"... rule this layer: always / conditional with a
    checkable trigger / not applicable?
    OWNER: Conditional... when someone touches the actual tooling.
    SKILL: State the trigger as a predicate evaluable mechanically from a diff.
    OWNER: If the diff touches tools/, or touches a script that has its own test
    suite.
    SKILL: Checkability confirmation -- reduces to path-membership checks: (a)
    changed path starts with tools/, or (b) changed path sits alongside
    *_test.*/test_*.*/*.spec.*. Ruling locked: CONDITIONAL | trigger: "diff touches
    tools/ or scripts with test suites".

### Link 3 -- docs/DOD.md index lines (written concretely)

    Ratified against DOD_TAXONOMY.md v1.
    - unit-tests: ALWAYS
    - mutation-testing: CONDITIONAL | trigger: diff touches tools/ or scripts with
      test suites
    - performance-benchmarking: N/A | category: target-absent | no perf-sensitive
      surface
    Stamp: v1
    Content-hash: sha256:<64-hex>

### Link 4 -- generated story DoD section (written concretely)

    ## Definition of Done
    *(derived from docs/DOD.md, ratified v1)*
    - [ ] Unit tests pass, evidence pasted inline (always-on)
    - [ ] Mutation testing: suite proven to catch a broken implementation of the
          touched tools/ code -- trigger fired ("diff touches tools/ or scripts
          with test suites"; this diff touches tools/); break the property, run
          suite, paste named failing case, restore

Author's note (NOT part of the generated artifact above): non-firing conditional
layers are simply ABSENT (no line, no N/A stub) -- FS2's refusal fires only for
ALWAYS layers omitted without a category-tagged N/A line.

### Link 5 -- completion-gate check (written concretely)

    For "Mutation testing" (trigger fired): evidence is the mutation run (break,
    run, paste failing case, restore). A green suite run alone is NOT evidence.
    Absent/generic evidence -> the literal line: DOD-GATE: FAIL mutation-testing
    Plus: stamp currency check (staleness warning), hash check (DOD-HASH: MISMATCH,
    warn-and-consume), malformed refusal.

### Verdict

All five links judged CONCRETE (complete text a consumer could act on).

WALKTHROUGH VERDICT: CONCRETE-AT-EVERY-LINK

Disclosed limits: proves the format for ONE layer under ONE ruling type; the
always-lifecycle, N/A-lifecycle, delta path, and A13 escape-hatch dialogue are
exercised by T2-T13 and the fixtures, not this walkthrough.
