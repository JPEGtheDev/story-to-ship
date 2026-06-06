# Greenfield App Skills -- Planning

## Feature Specification

*Written after Three Amigos Discovery Ceremony. Business + Tester findings only. Implementation details are in `## Implementation Notes` below.*

### What users can DO

1. **Discover** -- Invoke `greenfield-discovery` with a project idea (e.g., "I want to build a mathematical model simulator"). The skill interviews them using a bank of powerful questions, optionally reads provided documentation or whitepapers, and emits a `## Domain Model` block to the conversation. Context flows automatically to downstream skills.

2. **Architect** -- Invoke `greenfield-architecture` with or without a prior domain model (consumed automatically from conversation history if present). The skill asks about familiarity with candidate stacks and emits an `## Architecture Decision` block. Language and runtime are always decided; implementation-level choices (ORM, specific libraries) may be explicitly deferred.

3. **Defer** -- Invoke `defer-decision` on any specific architectural decision. The skill presents three diagnostic questions in a structured question box and emits one of three verdicts: `DECIDE NOW`, `DEFER -- revisit when [condition]`, or `[UNCLEAR:]`. Claude agents invoke this via the same structured question box, not silently.

4. **Challenge exceptions** -- Invoke `exception-philosophy` during planning or before writing implementation. The skill challenges each described exception-handling intent, classifies it as `SURFACE` / `LOG AND RETHROW` / `HANDLE`, and requires justification for any `HANDLE` verdict.

5. **Bootstrap** -- Invoke `greenfield-bootstrap` after context is established. The skill writes files to disk automatically: `.gitignore`, `README.md`, `.github/workflows/smoke.yml`, three issue templates, and a hello world entry point for the chosen stack. All written files are listed in a `## Bootstrapped Files` summary block.

### Acceptance Criteria (behavioral)

1. A developer can start with only "I want to build X" and reach a populated `## Domain Model` block without manually structuring their thoughts.
2. A developer can reach an `## Architecture Decision` block that names the language and runtime, and explicitly marks deferrable choices as `DEFERRED [condition]` rather than leaving them unaddressed.
3. A developer or Claude agent can challenge any architectural decision and receive a named-principle-backed verdict with a measurable re-entry condition when deferring.
4. A developer can describe an exception-handling intent and receive a classification with a specific question: "what happens if you don't catch this?" -- before any handling recommendation is made.
5. A developer can invoke bootstrap and have all project scaffold files written to disk and ready for a first commit, with a CI pipeline that passes on a clean checkout.
6. Context produced by each skill (domain model, architecture decision) is available to downstream skills without manual re-pasting.

### Explicitly OUT of scope

- Ongoing CI/CD beyond a smoke test (build + hello world run)
- Business logic implementation
- Full test suite generation
- Deployment, monitoring, or security review
- Execution or simulation of the generated code
- Stack-specific deep configuration (e.g., webpack configs, ORM migrations)

### Resolved questions (Discovery session)

- **Output mode (Story 5):** Files written to disk via Write tool, automated where possible.
- **Interview questions (Story 1):** Drawn from a powerful-questions bank covering problem, users, entities, and success criteria -- not a fixed rigid list.
- **Context chaining:** Domain model and architecture decision flow automatically from conversation history; no re-pasting required.
- **Low familiarity (Story 2):** Defined as self-reported "I've never used it", "I want to try it", or "I don't know the language syntax."
- **Architecture Decision completeness:** Language and runtime are required fields; persistence implementation (ORM choice, etc.) and API boundary detail are freely deferrable.
- **Agent invocation of defer-decision (Story 3):** Claude agents present all three diagnostic questions in a structured question box simultaneously, not one at a time.
- **Exception skill input (Story 4):** Operates on described exception-handling intent during planning or pre-implementation, not necessarily on pasted code.

---

## Stories

### Story 1: Greenfield Discovery Skill

**Title:** Greenfield Discovery Skill

**Type:** Feature
**Size:** M
**Epic/Component:** Greenfield App Skills
**Priority:** High
**Depends On:** None

**As a** developer starting a new project from scratch
**I want to** invoke a skill that interviews me using powerful questions and then asks for any supporting documentation
**So that** Claude has a structured domain model to reason from before recommending architecture or writing any code

#### Acceptance Criteria

- [ ] Skill draws from a question bank covering at minimum: what problem is being solved, who the users are, what the core entities/operations are, and what success looks like -- questions are powerful and open-ended, not a rigid fixed list
- [ ] After the interview, skill explicitly asks: "Do you have any supporting documentation, whitepapers, or domain references I should read?" and waits for a response before proceeding
- [ ] If docs are provided, skill reads them and merges extracted domain concepts with interview answers into a single domain summary block
- [ ] Domain summary block is labelled `## Domain Model` and is emitted to the conversation before the skill ends
- [ ] Skill surfaces `[UNCLEAR:]` labels for any answer that is internally contradictory (e.g., user states two mutually exclusive goals) or where a follow-up question reveals ambiguity
- [ ] Running the skill with "I want to build a mathematical model simulator" produces a populated `## Domain Model` with project-specific content (not a generic template with placeholder text)
- [ ] The `## Domain Model` block is automatically available to downstream skills (greenfield-architecture, greenfield-bootstrap) from conversation history without re-pasting

---

### Story 2: Greenfield Architecture & Stack Advisor Skill

**Title:** Greenfield Architecture & Stack Advisor Skill

**Type:** Feature
**Size:** M
**Epic/Component:** Greenfield App Skills
**Priority:** High
**Depends On:** None (consumes `## Domain Model` from conversation history if present; asks minimal context questions if absent)

**As a** developer who has a domain model or general idea
**I want to** invoke a skill that recommends a language, stack, and initial architecture
**So that** I start building on a foundation that fits the problem and my own ability to maintain it, not just Claude's default preference

#### Acceptance Criteria

- [ ] Skill reads `## Domain Model` from conversation history if present; otherwise asks a minimal set of context questions (problem type, output type, deployment target) before proceeding
- [ ] Skill asks the user to self-report familiarity with candidate languages/stacks before making a recommendation
- [ ] Low familiarity is defined as any self-report of: "I've never used it", "I want to try it", or "I don't know the syntax" -- skill flags this and asks if the user wants an alternative
- [ ] Recommendation output includes: primary language, runtime/framework, and a one-sentence rationale for each choice
- [ ] Skill produces an `## Architecture Decision` block that always includes: language (required) and runtime (required); persistence and API boundary are included if decided, or marked `DEFERRED -- revisit when [condition]` if not
- [ ] Implementation-level choices (ORM, specific libraries, query strategy) are explicitly deferred with a named re-entry condition, not omitted silently
- [ ] Skill references the `defer-decision` skill by name when marking any item as `DEFERRED`

---

### Story 3: Architectural Decision Deferral Skill

**Title:** Architectural Decision Deferral Skill

**Type:** Feature
**Size:** S
**Epic/Component:** Greenfield App Skills / Architecture
**Priority:** Medium
**Depends On:** None

**As a** developer or Claude agent evaluating an architectural decision
**I want to** invoke a skill that challenges whether a decision needs to be made right now
**So that** I avoid premature architectural lock-in and keep early-stage code reversible

#### Acceptance Criteria

- [ ] Skill presents all three diagnostic questions simultaneously in a structured question box: (1) Does making this decision now constrain anything that isn't yet built? (2) Can this decision be reversed cheaply in two sprints? (3) Does deferring this decision block the current vertical slice?
- [ ] When invoked by Claude as an agent (not a human), the same structured question box is presented -- the agent does not self-answer silently
- [ ] Skill outputs one of three verdicts: `DECIDE NOW`, `DEFER -- revisit when [condition]`, or `[UNCLEAR:] -- answer [question] before deciding`
- [ ] `DEFER` verdict includes a concrete re-entry condition stated as a measurable event (e.g., "when the first integration test touches the database layer"), never a vague statement like "when the time is right"
- [ ] Skill cites at least one named principle per verdict: YAGNI for `DEFER`, a named technical risk for `DECIDE NOW`
- [ ] Skill refuses to output `DEFER` when already-built code would require changes to accommodate the deferred choice

---

### Story 4: Exception Philosophy Skill (Skeptic Mode)

**Title:** Exception Philosophy Skill

**Type:** Feature
**Size:** S
**Epic/Component:** Code Quality / Exception Handling
**Priority:** Medium
**Depends On:** None

**As a** developer planning exception handling before or during implementation
**I want to** invoke a skill that challenges each exception-handling intent and asks "do you actually need to handle this?"
**So that** real failures surface as crashes or logs rather than being silently swallowed, and I don't build false safety nets that hide production problems

#### Acceptance Criteria

- [ ] Skill operates on described exception-handling intent (at planning or pre-implementation time) -- input is a description of what the developer intends to catch and why, not necessarily pasted code
- [ ] For each described exception site, skill asks first: "What happens if you don't catch this?" before recommending any handling
- [ ] Skill classifies each exception into one of three categories: `SURFACE` (let it propagate -- do not catch), `LOG AND RETHROW` (observe but do not swallow), `HANDLE` (genuine recovery is possible and defined)
- [ ] `HANDLE` verdict requires the developer to state: what concrete recovery action will be taken, and how that recovery will be tested
- [ ] Skill refuses to approve a `HANDLE` verdict for any catch that targets a broad base type (e.g., `Exception`, `Error`, `std::exception`) without a specific recovery action or re-raise
- [ ] Skill references C2 `DontCatchExceptions`, `LetItCrash`, and `FailFast` as named rationale (at least one per verdict, all three cited over the course of a session)
- [ ] Skill explicitly states: "An unhandled exception that crashes is more useful than a handled exception that hides a bug"

---

### Story 5: Greenfield Project Bootstrapping Skill

**Title:** Greenfield Project Bootstrapping Skill

**Type:** Feature
**Size:** M
**Epic/Component:** Greenfield App Skills
**Priority:** High
**Depends On:** None (consumes `## Domain Model` and `## Architecture Decision` from conversation history if present; asks for stack if absent)

**As a** developer who has a domain model and an architecture decision
**I want to** invoke a skill that writes all project scaffold files to disk automatically
**So that** the repository is immediately ready for GitHub issue-driven development without manual file creation

#### Acceptance Criteria

- [ ] Skill reads `## Domain Model` and `## Architecture Decision` from conversation history automatically; if stack is still unknown after reading, skill asks once before generating any file
- [ ] Skill writes `.gitignore` to disk appropriate for the chosen stack
- [ ] Skill writes `README.md` to disk seeded from the domain model; README includes: project name, one-paragraph purpose, prerequisites, and a "how to run" section
- [ ] Skill writes `.github/workflows/smoke.yml` to disk: a GitHub Actions workflow that checks out the repo, installs/builds, runs the hello world entry point, and exits non-zero if the hello world fails
- [ ] Skill writes three issue templates to disk at `.github/ISSUE_TEMPLATE/`: `bug_report.md`, `user_story.md` (matching the story format used in this repo's plan.md), and `spike.md`
- [ ] Skill writes a hello world entry point to disk at the conventional path for the chosen stack; it prints one line containing the project name and exits 0
- [ ] All written file paths are listed in a `## Bootstrapped Files` summary block emitted at the end of the skill run
- [ ] All file writes are performed via automated tool calls (Write tool), not printed to conversation for manual copy-paste

---

## Implementation Notes

*Developer Amigo findings from Discovery Ceremony. These inform todo planning but do not belong in the Feature Specification.*

### Skill Architecture Constraints

- Every skill file must satisfy the 5-element anatomy: FRONTMATTER, IRON LAW, ANNOUNCEMENT, GATE FUNCTION, RATIONALIZATION TABLE (source: `skills/writing-skills/SKILL.md`).
- Every non-trivial rule must answer: Context, Forces, Solution, Consequences (Alexandrian Pattern Form).
- **1% session frequency gate:** The `writing-skills` skill requires that a skill be used in >=1% of sessions before a standalone skill file is justified. All 5 stories must satisfy this or become reference docs. Story 3 (defer-decision) is most at risk -- it overlaps with `brainstorming` Phase 3. Consider making it `brainstorming/references/DECISION_DEFERRAL.md` unless standalone frequency justifies it.

### Domain Model Block Schema

- No schema is currently defined. Stories 2 and 5 consume the `## Domain Model` block. A field schema must be defined as part of Story 1's implementation to prevent heuristic parsing downstream.
- Minimum fields suggested: `Problem`, `Users`, `Core Entities`, `Success Criteria`, `Open Questions`.

### Inter-skill Invocation Chain

- Story 2 references the `defer-decision` skill by name. "Referencing" means citing the skill name as a text label, not a runtime tool invocation -- clarified in Discovery.
- All 5 skills need dispatch table entries in `skills/session-bootstrap/references/SKILL_DISPATCH_TABLE.md` and `skills/session-bootstrap/SKILL.md`.
- Exception-philosophy should appear alongside `code-quality` in the dispatch table row for "writing or reviewing code", not as a separate exclusive trigger.

### Test Fixtures Needed (per story)

- Story 1: Fixture prompt "I want to build a mathematical model simulator" + a short fixture document (whitepaper excerpt).
- Story 2: Fixture `## Domain Model` block for the simulator domain; fixture for no-domain-model path.
- Story 3: Three fixture decisions -- one reliably producing each verdict (DECIDE NOW, DEFER, UNCLEAR).
- Story 4: Four fixture exception descriptions -- one per classification plus one broad-base-type case.
- Story 5: Three fixture combinations -- (a) full context present, (b) stack absent only, (c) both absent.
