# DoD Canon Authoring Template

This is the authoring template for a repo's ratified Definition of Done (DoD) canon:
the flat index file `docs/DOD.md` and its optional per-layer detail files under
`docs/dod/<group-slug>/<layer-key>.md`. The defining-done ratification interview
(SKILL.md) and any future interview tooling MUST produce output conforming to this
template exactly. Nothing here is pre-filled content -- every ruling, trigger, and
elaboration below is illustrative only.

---

## A. Canon index format (docs/DOD.md)

`docs/DOD.md` is a cross-cutting standard file per the documentation skill's
file-naming convention (`docs/UPPERCASE.md`). It MUST stay under the documentation
skill's 800-token cap -- one line per taxonomy layer, no elaboration beyond a short
optional free-text tail on N/A lines. Longer rationale goes to a detail file (Section
B), never into the index.

### A.1 Frontmatter

`docs/DOD.md` MUST begin with YAML frontmatter matching the documentation skill's
**Cross-cutting standard files** template exactly -- this is the field
set for `docs/UPPERCASE.md` files, and `docs/DOD.md` is one: `title`, `description`,
`domain: cross-cutting`, `tags`, `related`. There is no `subdomain` field on this
template -- do not add one; the flat index has no taxonomy group of its own, and
cross-cutting files do not carry `subdomain`. There is also no `version` field --
that field is a dropped, deliberately absent artifact, unrelated to the `Stamp:`
mechanism below. `tags` MUST start `[cross-cutting, standards, ...]` (per the
template) followed by `dod` and any additional tags. `related` MUST link to
`docs/INDEX.md` and to each detail file this canon has.

### A.2 Machine-readable stamp

Exactly ONE machine-readable stamp field exists in the canon: a line of the exact
form

```
Stamp: vN
```

where `N` is a monotonic integer matching the taxonomy stamp the canon was last
ratified or delta-ratified against. `Stamp: vN` is the single
source of truth consumers read to detect staleness (Section C). A human-readable
narrative line such as `Ratified against DOD_TAXONOMY.md vN.` MAY also appear
immediately above the ruling lines as optional, non-normative prose -- it exists for
human readability only. No consumer (generator, completion gate, or any other
tooling) MUST ever parse the narrative line; `Stamp: vN` is authoritative and the
narrative line, if present, MUST agree with it or be treated as a documentation bug,
not a second source of truth.

### A.3 Ruling lines

The index carries exactly one ruling line per taxonomy layer, keyed by that layer's
canonical `Key` field from `DOD_TAXONOMY.md` (kebab-case). Every taxonomy layer MUST
have exactly one line in the index -- no omissions, no defaults, no layer left
unruled. There are exactly three ruling forms, a closed list -- no other form is
valid:

```
- <key>: ALWAYS
- <key>: CONDITIONAL | trigger: <objectively checkable predicate>
- <key>: N/A | category: <target-absent|covered-elsewhere|repo-ruled-N/A> [| <optional free-text elaboration>]
```

Rules for each form:
- `ALWAYS` -- the layer is required on every change. No trigger, no category.
- `CONDITIONAL` -- the layer applies only when its trigger predicate fires against a
  given diff. The trigger MUST be objectively checkable (mechanically evaluable from
  the diff, per the ratification interview's checkability re-elicitation loop) -- not
  a subjective judgment call.
- `N/A` -- the layer never applies in this repo. `category` MUST be one of the three
  closed values: `target-absent` (the repo has no surface this layer verifies),
  `covered-elsewhere` (another layer or repo mechanism already covers the same
  concern), or `repo-ruled-N/A` (the product owner ruled it out for a repo-specific
  reason not captured by the first two categories). An optional free-text
  elaboration MAY follow the category tag after a second `|`.

A ruling line MAY soft-wrap: an indented continuation line belongs to the ruling line
above it and is parsed as part of that single ruling line, as the worked example in
Section A.5 shows. Continuation lines are not independently checked against the three
forms.

### A.4 Canon integrity

The canon carries no integrity field of its own, and one MUST NOT be added. Integrity
is version control's job: an uncommitted edit to `docs/DOD.md` is visible in
`git status` and `git diff`, and a committed edit is visible in the file's history
via `git log` and `git blame`. A reviewer asking whether the canon changed, and how,
reads that history rather than a value recorded inside the file itself.

The index MUST end with the `Stamp:` line (Section A.2), and content MUST NOT follow it.
Trailing content would present lines the malformed-canon rule in Section C cannot
distinguish from invalid ruling lines -- the annotated links under a `## Related`
heading, for one, open much like ruling lines. Ending at the stamp is a deliberate,
scoped exception to the documentation skill's rule that every doc file ends with a
`## Related` section: the exception covers only `docs/DOD.md`, the index; detail files
keep the requirement per Section B.3.

### A.5 Worked example (canonical form)

The block below is a fully worked, non-normative example. It uses real taxonomy
Keys from `DOD_TAXONOMY.md` -- `coverage` for an ALWAYS ruling, `mutation-testing`
for a CONDITIONAL ruling, and `performance-spend-budgets` for an N/A ruling:

```
Ratified against DOD_TAXONOMY.md v1.
- coverage: ALWAYS
- mutation-testing: CONDITIONAL | trigger: diff touches tools/ or scripts with
  test suites
- performance-spend-budgets: N/A | category: target-absent | no perf-sensitive
  surface or metered API calls in this repo
Stamp: v1
```

---

## B. Detail-file format (docs/dod/<group-slug>/<layer-key>.md)

### B.1 When a detail file exists

Detail files are OPTIONAL per layer -- created only when a ruling's rationale or
elaboration exceeds what the index line's optional free-text tail can carry. The
index stays lean by design; anything longer belongs in a detail file
linked from the index's `related` frontmatter field.

### B.2 Path and the group-slug transform

Path shape: `docs/dod/<group-slug>/<layer-key>.md`, where `<layer-key>` is the
taxonomy layer's canonical `Key` (already kebab-case, taken verbatim from
`DOD_TAXONOMY.md`) and `<group-slug>` is derived from the layer's `Group` field by
this exact transform: lowercase the group name, drop every `&` character, collapse
any resulting run of whitespace to a single space, then replace each remaining
space with a hyphen (existing hyphens inside the group name, e.g. from
`Test-Suite`, are left untouched).

Applied to all five current `DOD_TAXONOMY.md` groups, this transform produces:

| Group (DOD_TAXONOMY.md) | group-slug |
|---|---|
| `Acceptance & Traceability` | `acceptance-traceability` |
| `Test-Suite Integrity` | `test-suite-integrity` |
| `Non-Functional Verification` | `non-functional-verification` |
| `Process & Static Gates` | `process-static-gates` |
| `Release Readiness` | `release-readiness` |

Example full paths: `docs/dod/test-suite-integrity/mutation-testing.md`,
`docs/dod/process-static-gates/documentation-updates.md`.

### B.3 Frontmatter and content rules

Detail-file frontmatter follows the documentation skill's frontmatter schema for an
individual reference file: `title`, `description`, `domain: dod`,
`subdomain: <group-slug>`, `tags` starting `[dod, <group-slug>, <layer-key>]`, and
`related` linking back to `docs/DOD.md` and to `DOD_TAXONOMY.md`. A `## Related`
section is required at the bottom, per the documentation skill's convention. The
per-file 800-token cap applies -- one concept (one layer's rationale) per file.

### B.4 Write order

Canon writes happen in exactly this order, as a single atomic write step performed
only at ratification (or delta re-ratification): (1) detail files; (2) when any
detail files exist, the per-level index chain for them -- `docs/dod/<group-slug>/INDEX.md`
for each group directory that has detail files, then `docs/dod/INDEX.md` linking
those subdomain indexes (create or update either as needed), per the documentation
skill's per-level INDEX.md rule; (3) `docs/DOD.md`; (4) the `docs/INDEX.md` update --
a row for DOD.md plus a row linking `docs/dod/INDEX.md` when it exists (never a row for individual leaf
detail files at root; that is the child index's job). Nothing is written before this
step -- an interview abandoned before the final ratification pass leaves no file
changed. Because `docs/DOD.md` is written after every file under `docs/dod/` and
before the `docs/INDEX.md` update, its presence remains the reliable canon signal:
an interruption anywhere under `docs/dod/` (detail files or their index chain)
before `docs/DOD.md` is written means no canon exists yet at all (its absence is the
"no canon" state consumers check for), leaving at most inert orphan files under
`docs/dod/`; an interruption between `docs/DOD.md` and the `docs/INDEX.md` update
leaves a live canon with a stale root index (inert, not live).

---

## C. Consumer notes

Downstream consumers (the story generator and the completion gate) MUST quote these
three literal marker strings verbatim -- this section is the canonical source for all
three:

- `DOD-VIOLATION: <layer>` -- the generator's refusal marker, emitted when a story
  omits an ALWAYS layer with no category-tagged N/A line.
- `DOD-GATE: FAIL <layer>` -- the completion gate's failure marker, emitted when a
  completion claim lacks evidence for an ALWAYS layer or a CONDITIONAL layer whose
  trigger fired.
- `DOD-STALE: canon v<N> behind taxonomy v<M>` -- emitted by either consumer when the
  canon's `Stamp: vN` is older than `DOD_TAXONOMY.md`'s current stamp. The canon is
  STILL consumed: staleness is a currency warning, not a refusal trigger. Never
  silently consume a stale canon as if it were current.

**Emission format:** a marker is emitted as a bare line -- the line begins with the
marker string itself, with no surrounding formatting: no backticks, no list markers,
no quotation marks, no leading whitespace. The markers appear in backticks above only
because this section is prose describing them; emitted output carries none.

One additional non-marker rule applies to every consumer:

- **Malformed-canon rule:** if `docs/DOD.md` exists but its structure cannot be
  parsed (a missing or unparseable `Stamp:` line, or a ruling line matching none of
  the three forms in Section A.3), consumers MUST refuse with a diagnostic
  naming what failed to parse. Never silently fall back to the canon-less default as
  if no canon existed at all -- "present but unreadable" and "absent"
  are different states and MUST produce different, observable behavior.

---

## Related

- [DOD_TAXONOMY.md](DOD_TAXONOMY.md) -- the repo-agnostic layer list this template's
  index and detail files instantiate; supplies each layer's `Key` and `Group`.
- [INDEX.md](INDEX.md) -- this skill's reference-file catalog.
- [../SKILL.md](../SKILL.md) -- the ratification interview that produces canon
  conforming to this template.
