# Definition of Done Taxonomy

This is a repo-agnostic taxonomy of verification layers a change can be checked
against. It is not itself a Definition of Done -- each repo's `docs/DOD.md` is the
instantiation, produced by running the defining-done interview and ruling every layer
below as always-required, conditional with a checkable trigger, or not applicable with
a reason. No ruling is ever pre-filled in this file or in an interview; every ruling
comes from the product owner.

Stamp: v1
Delta rule: a re-ratification interview against a newer stamp elicits ONLY the layers
added or changed since the canon's recorded stamp; every other prior ruling is left
untouched.

Key transform: each layer's `Key` is the layer name lowercased, with spaces and
slashes converted to hyphens, and any parenthetical suffix dropped.

---

## Acceptance & Traceability

### BDD Tests

**Key:** bdd-tests
**Group:** Acceptance & Traceability
**Verifies:** that Behavior-Driven Development (BDD) scenarios are specified and
validated in a shared, business-readable language (Given/When/Then) tying acceptance
criteria directly to executable scenarios, so a passing scenario means the described
behavior actually occurs -- not just that some code ran.
**Example checkable triggers:**
- diff adds or modifies a `*.feature` file
- diff touches step-definition files under a `features/` or `spec/steps` directory
  alongside a `*.feature` change

### UAT

**Key:** uat
**Group:** Acceptance & Traceability
**Verifies:** that User Acceptance Testing (UAT) -- a human representative of the
target user (or the product owner standing in for them) exercising the change in a
realistic environment -- confirms it satisfies the actual need, not just the written
spec.
**Example checkable triggers:**
- diff changes any path matching the repo's configured user-facing-surface globs
  (e.g. `ui/**`, `app/**`)
- diff's PR/commit body carries the repo's user-facing marker convention

### Automated Acceptance Tests

**Key:** automated-acceptance-tests
**Group:** Acceptance & Traceability
**Verifies:** that the acceptance criteria for a story are checked by an automated
suite independent of unit tests, so acceptance status does not depend on a human
re-verifying it by hand every time the suite runs.
**Example checkable triggers:**
- diff adds or modifies files under an `acceptance/` or `e2e-acceptance/` test
  directory
- diff changes a story/issue whose linked acceptance-criteria (AC) block references
  an automated test path

### AC-to-Test Traceability

**Key:** ac-to-test-traceability
**Group:** Acceptance & Traceability
**Verifies:** that every acceptance criterion (AC) named for a story maps to at
least one identifiable test, so "AC met" is a checkable claim rather than an
assertion taken on faith.
**Example checkable triggers:**
- diff closes or references a story/issue whose body contains a numbered AC list
- diff adds test files with no comment/tag linking back to an AC identifier, in a repo
  that requires the tag convention

---

## Test-Suite Integrity

### Mutation Testing

**Key:** mutation-testing
**Group:** Test-Suite Integrity
**Verifies:** that the tests covering the changed code actually detect a broken
implementation -- not merely that the suite executes and reports pass.
**Example checkable triggers:**
- diff touches any path under `tools/`
- diff touches any path with a co-located test suite (`*_test.*`, `test_*.*`,
  `*.spec.*` in the same directory or an adjacent `tests/` directory)

### Contract Tests

**Key:** contract-tests
**Group:** Test-Suite Integrity
**Verifies:** that a producer and a consumer of an interface (API, message schema,
abstract base class) agree on that interface's shape and behavior, catching breakage
that unit tests on either side alone would miss.
**Example checkable triggers:**
- diff modifies a file matching `*_client.*`, `*_server.*`, or a schema file
  (`*.proto`, `*.graphql`, `openapi*.yaml`)
- diff modifies an abstract base class or interface file that has more than one
  implementing subclass in the repo

### Property-Based Tests

**Key:** property-based-tests
**Group:** Test-Suite Integrity
**Verifies:** that a stated invariant holds across a generated range of inputs, not
just the specific example values a hand-written unit test happened to choose.
**Example checkable triggers:**
- diff touches a function under a path the repo configures as property-testable
  (numeric, collection, parser/serializer logic)
- diff modifies an existing property-based test file (matching `*_prop_test.*`,
  `*.properties.*`)

### Integration/E2E Split

**Key:** integration-e2e-split
**Group:** Test-Suite Integrity
**Verifies:** that fast integration tests (component boundaries, in-process) and slow
end-to-end tests (full stack, real or near-real environment) each exist at the right
layer, so failures are localized and the suite stays fast enough to run often.
**Example checkable triggers:**
- diff adds a new service/module boundary (a new directory with its own entry point)
  with no corresponding integration test directory
- diff modifies a cross-service call path (touches two or more top-level service
  directories in one commit)

### Coverage

**Key:** coverage
**Group:** Test-Suite Integrity
**Verifies:** that newly written code is exercised by the test suite at both the
line and branch level above an agreed new-code threshold, catching code paths
that ran zero times during testing.
**Example checkable triggers:**
- diff adds new source lines in a path included in the repo's coverage configuration
- diff adds a new conditional branch (if/else, switch case, ternary) with no
  corresponding test-file change in the same commit

---

## Non-Functional Verification

### Visual Regression

**Key:** visual-regression
**Group:** Non-Functional Verification
**Verifies:** that rendered output (user interface (UI), generated images, rendered
documents) has not silently drifted in appearance -- a change to pixels or layout is
caught even when no functional test would notice it.
**Example checkable triggers:**
- diff touches a file under a directory the repo recognizes as UI (e.g.
  `components/`, `views/`)
- diff touches any shader file, graphics-rendering code, or image-generation path

### Performance/Spend Budgets

**Key:** performance-spend-budgets
**Group:** Non-Functional Verification
**Verifies:** that the change stays within an agreed resource envelope (latency,
memory, compute cost, API/token spend) rather than silently regressing a budget
nobody is watching.
**Example checkable triggers:**
- diff touches a hot-path file listed in the repo's performance-budget configuration
- diff adds or modifies a call to a metered/paid API (Large Language Model (LLM)
  calls, cloud Software Development Kit (SDK) calls)

### Security Scanning

**Key:** security-scanning
**Group:** Non-Functional Verification
**Verifies:** that the change does not introduce a known-vulnerable dependency, a
committed secret or credential, or a static security anti-pattern (injection, unsafe
deserialization) into the codebase.
**Example checkable triggers:**
- diff modifies a dependency manifest or lockfile (`package.json`,
  `requirements.txt`, `go.mod`, `Cargo.lock`)
- diff adds a string matching a high-entropy (statistically random-looking, as
  secret scanners flag) or credential-shaped pattern (API key, private key block,
  connection string)

### Observability/Diagnosability

**Key:** observability-diagnosability
**Group:** Non-Functional Verification
**Verifies:** that when the change misbehaves in production, there is enough
logging, metrics, or tracing to diagnose it without having to reproduce it locally
from scratch.
**Example checkable triggers:**
- diff adds a new external call (network, disk, subprocess) with no adjacent
  log/metric emission
- diff adds a new error/exception path with no corresponding log statement or error
  code

---

## Process & Static Gates

### Lint/Format/Static Analysis

**Key:** lint-format-static-analysis
**Group:** Process & Static Gates
**Verifies:** that the code adheres to the repo's mechanical style and
correctness-adjacent static rules (formatting, unused variables, type errors) before
any human or dynamic check runs.
**Example checkable triggers:**
- diff touches a file whose extension is covered by the repo's linter configuration
- diff differs from the output of re-running the repo's formatter on the same files

### 2-Stage Review

**Key:** 2-stage-review
**Group:** Process & Static Gates
**Verifies:** that a change is checked twice by independent reviewers or reviewer
roles -- once for spec/functional compliance, once for code quality/standards --
catching what a single pass misses.
**Example checkable triggers:**
- diff's PR has fewer than two distinct recorded review approvals
- diff touches a path the repo's CODEOWNERS marks as requiring two reviewers

### Versioning/Conventional Commits

**Key:** versioning-conventional-commits
**Group:** Process & Static Gates
**Verifies:** that the change's commit messages and any version bump follow the
repo's declared convention, so automated changelog and release tooling can consume
history reliably.
**Example checkable triggers:**
- diff's commit message does not match the conventional-commits pattern
  `<type>[scope]: <description>`
- diff changes a package manifest's version field inconsistently with the commit
  type (e.g. a breaking change with no major-version bump)

### Documentation Updates

**Key:** documentation-updates
**Group:** Process & Static Gates
**Verifies:** that user-facing or developer-facing behavior changes are reflected in
the repo's documentation in the same change, so docs never silently drift from code.
**Example checkable triggers:**
- diff modifies a public API signature, command-line interface (CLI) flag, or
  config schema with no corresponding `docs/` file change in the same commit
- diff adds a new module/skill/component with no accompanying README or INDEX.md
  entry

---

## Release Readiness

### Exploratory Testing

**Key:** exploratory-testing
**Group:** Release Readiness
**Verifies:** that a human has spent unscripted time probing the change for behavior
that no automated test or acceptance criterion anticipated.
**Example checkable triggers:**
- diff is tagged high-risk or novel-surface in the PR body (repo-defined marker)
- diff touches a path with no existing automated test coverage at all (greenfield
  surface)

### Rollback/Release Criteria

**Key:** rollback-release-criteria
**Group:** Release Readiness
**Verifies:** that there is a defined, checkable condition under which the change
would be rolled back or the release halted, so shipping is not a one-way door decided
ad hoc under pressure.
**Example checkable triggers:**
- diff touches a deploy/release config file (CI workflow, feature-flag config,
  migration script)
- diff includes a database migration with no paired down-migration/rollback script

### Definition of Ready

**Key:** definition-of-ready
**Group:** Release Readiness
**Verifies:** that the work item itself (story/issue) met an agreed bar --
acceptance criteria stated, dependencies known, estimated -- before implementation
began, catching scope and ambiguity problems before they become code problems.
**Example checkable triggers:**
- diff's linked story/issue lacks a numbered acceptance-criteria section at the time
  work started
- diff's linked story/issue has an open blocking dependency reference unresolved at
  commit time
