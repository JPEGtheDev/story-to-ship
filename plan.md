# Greenfield App Skills -- Planning

## Feature Specification

*Written after Three Amigos Discovery Ceremony. Refined after Refinement Ceremony. Business + Tester findings only.*

### What users can DO

1. **Discover** -- Invoke `greenfield-discovery` with a project idea (e.g., "I want to build a mathematical model simulator"). The skill interviews them using a bank of powerful questions, optionally reads provided documentation or whitepapers, and emits a `## Domain Model` block to the conversation. Context flows automatically to downstream skills.

2. **Architect** -- Invoke `greenfield-architecture` with or without a prior domain model (consumed automatically from conversation history if present). The skill evaluates each architectural decision using the embedded deferral diagnostic automatically -- no separate skill invocation required. Emits an `## Architecture Decision` block. Language and runtime are always decided; implementation-level choices may be explicitly deferred.

3. **Challenge exceptions** -- Invoke `exception-philosophy` during planning or before writing implementation. The skill challenges each described exception-handling intent, classifies it as `SURFACE` / `LOG AND RETHROW` / `HANDLE`, and requires justification for any `HANDLE` verdict.

4. **Bootstrap** -- Invoke `greenfield-bootstrap` after context is established. The skill writes files to disk automatically for the chosen stack (Python, TypeScript/Node.js, Rust, Go, C#, C++, C/embedded C): `.gitignore`, `README.md`, `.github/workflows/smoke.yml`, three issue templates, and a hello world entry point. All written files are listed in a `## Bootstrapped Files` summary block.

5. **Deferral diagnostic (embedded)** -- The deferral logic (three diagnostic questions, three verdicts, YAGNI/named-risk rationale) runs automatically within `greenfield-architecture` and `brainstorming` whenever an architectural decision is evaluated. No separate skill invocation. The canonical logic lives in `brainstorming/references/DECISION_DEFERRAL.md`.

### Acceptance Criteria (behavioral)

1. A developer can start with only "I want to build X" and reach a populated `## Domain Model` block without manually structuring their thoughts.
2. A developer can reach an `## Architecture Decision` block that names the language and runtime, and explicitly marks deferrable choices as `DEFERRED [condition]` rather than leaving them unaddressed -- without invoking any separate skill.
3. A developer can describe an exception-handling intent and receive a classification with a specific question: "what happens if you don't catch this?" -- before any handling recommendation is made.
4. A developer can invoke bootstrap and have all project scaffold files written to disk and ready for a first commit, with a CI pipeline that passes on a clean checkout.
5. Context produced by each skill (domain model, architecture decision) is available to downstream skills without manual re-pasting.

### Explicitly OUT of scope

- Standalone `defer-decision` skill that must be explicitly invoked
- Ongoing CI/CD beyond a smoke test (build + hello world run)
- Business logic implementation
- Full test suite generation
- Deployment, monitoring, or security review
- Execution or simulation of the generated code
- Stack-specific deep configuration (e.g., webpack configs, ORM migrations)
- Stacks not in the bounded list: Python, TypeScript/Node.js, Rust, Go, C#, C++, C/embedded C

### Resolved questions (Discovery + Refinement)

- **Output mode (Story 4):** Files written to disk via Write tool, automated. No file content printed to conversation for copy-paste.
- **Interview questions (Story 1):** Drawn from a powerful-questions bank -- not a fixed rigid list.
- **Context chaining:** Domain model and architecture decision flow automatically from conversation history. When multiple `## Domain Model` blocks exist, the most recent is used.
- **Low familiarity (Story 2):** "I've never used it", "I want to try it", or "I don't know the syntax." Skill emits `[LOW FAMILIARITY]` marker and asks if user wants an alternative.
- **Architecture Decision completeness:** Language and runtime required; persistence/API boundary deferrable with named re-entry condition.
- **Deferral diagnostic (Story 3):** Embedded in `greenfield-architecture` and `brainstorming` via `brainstorming/references/DECISION_DEFERRAL.md`. Not an invocable standalone skill.
- **Exception skill input (Story 4):** Operates on described intent during planning/pre-implementation -- not necessarily pasted code.
- **Bounded stacks (Story 4):** Python, TypeScript/Node.js, Rust, Go, C#, C++, C/embedded C. Other stacks produce "unsupported stack" response.
- **Measurable re-entry condition rubric:** A condition is measurable if it names a specific observable event (e.g., "when the first integration test hits the database layer"). Vague conditions ("when the time is right", "later") are rejected.

---

## Stories

*Recommended implementation order: 1 → 2 → 4 (bootstrap) → 3 (exception) → reference doc (deferral). Stories 1, 2, and 4 deliver the full end-to-end greenfield flow first.*

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

- [ ] Skill draws from a question bank covering at minimum: what problem is being solved, who the users are, what the core entities/operations are, and what success looks like -- questions are powerful and open-ended, not a rigid closed list
- [ ] The documentation question ("Do you have any supporting documentation, whitepapers, or domain references I should read?") is the last line of the interview phase output; the `## Domain Model` block does not appear until the user has answered this question
- [ ] If docs are provided, skill reads them and merges extracted domain concepts with interview answers into a single domain summary block
- [ ] Domain summary block is labelled `## Domain Model` and contains project-specific content (not placeholder text)
- [ ] Skill surfaces `[UNCLEAR:]` labels for any answer that is internally contradictory (e.g., user states two mutually exclusive goals)
- [ ] Running the skill with "I want to build a mathematical model simulator" produces a populated `## Domain Model` containing domain-specific vocabulary (e.g., "simulator", "model", "equations") rather than generic placeholders
- [ ] When `greenfield-architecture` or `greenfield-bootstrap` is invoked in a conversation already containing a `## Domain Model` block, those skills do not ask the user to re-describe or re-paste the domain model

#### Additional scope
- Creates `skills/greenfield-discovery/references/DOMAIN_MODEL_SCHEMA.md` defining minimum required fields: Problem, Users, Core Entities, Success Criteria, Open Questions
- Adds `greenfield-discovery` entry to `skills/session-bootstrap/references/SKILL_DISPATCH_TABLE.md` and `skills/session-bootstrap/SKILL.md` (owns all 5 new dispatch table entries as first-delivered skill)

---

### Story 2: Greenfield Architecture & Stack Advisor Skill

**Title:** Greenfield Architecture & Stack Advisor Skill

**Type:** Feature
**Size:** M
**Epic/Component:** Greenfield App Skills
**Priority:** High
**Depends On:** None (consumes `## Domain Model` from conversation history if present; asks minimal context questions if absent)

**As a** developer who has a domain model or general idea
**I want to** invoke a skill that recommends a language, stack, and initial architecture -- with deferral decisions made automatically
**So that** I start building on a foundation that fits the problem and my own ability to maintain it, without invoking a separate decision tool

#### Acceptance Criteria

- [ ] Skill reads `## Domain Model` from conversation history if present; if multiple blocks exist, uses the most recent one; if absent, asks a minimal set of context questions (problem type, output type, deployment target) before proceeding
- [ ] Skill asks the user to self-report familiarity with candidate languages/stacks before making a recommendation
- [ ] When the user reports low familiarity ("I've never used it", "I want to try it", or "I don't know the syntax"), skill emits a `[LOW FAMILIARITY]` marker followed by an explicit question: "Would you like me to suggest an alternative stack?"
- [ ] Recommendation output includes: primary language, runtime/framework, and a one-sentence rationale for each choice
- [ ] Skill applies the deferral diagnostic (from `brainstorming/references/DECISION_DEFERRAL.md`) to each architectural decision automatically -- no separate skill invocation required
- [ ] Skill produces an `## Architecture Decision` block that always includes: language (required) and runtime (required); persistence and API boundary are included if decided, or marked `DEFERRED -- revisit when [condition]` if the deferral diagnostic recommends deferral
- [ ] Implementation-level choices (ORM, specific libraries) are explicitly deferred with a concrete, measurable re-entry condition -- never omitted silently or marked with vague conditions like "later"

---

### Story 3: Architectural Decision Deferral Reference

**Title:** Architectural Decision Deferral Reference

**Type:** Feature
**Size:** S
**Epic/Component:** Greenfield App Skills / Architecture
**Priority:** Medium
**Depends On:** Story 2 (wired into greenfield-architecture)

**As a** developer working through architecture and design decisions
**I want to** the deferral diagnostic to run automatically within the architecture and brainstorming workflows
**So that** I get YAGNI-backed deferral guidance without invoking a separate skill

#### Acceptance Criteria

- [ ] Creates `skills/brainstorming/references/DECISION_DEFERRAL.md` containing: three diagnostic questions, three verdict types (`DECIDE NOW` / `DEFER -- revisit when [condition]` / `[UNCLEAR:] -- answer [question]`), YAGNI rationale for DEFER, named-risk rationale for DECIDE NOW, and a measurability rubric for re-entry conditions
- [ ] Measurability rubric includes: one positive example ("when the first integration test touches the database layer" = measurable) and one negative example ("when the time is right" = not measurable)
- [ ] `greenfield-architecture` skill (Story 2) loads and applies `DECISION_DEFERRAL.md` for every architectural decision it evaluates
- [ ] The existing `brainstorming` skill's Phase 3 design gate references `DECISION_DEFERRAL.md` for defer/decide evaluation
- [ ] Given the fixture decision "Should I use an ORM or raw SQL?", the deferral diagnostic produces `DEFER` with a measurable re-entry condition
- [ ] Given the fixture decision "What is the primary programming language for this project?", the deferral diagnostic produces `DECIDE NOW` with a named rationale
- [ ] Skill refuses to mark any item `DEFER` with a re-entry condition containing only vague language ("later", "when needed", "eventually")

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
**So that** real failures surface as crashes or logs rather than being silently swallowed

#### Acceptance Criteria

- [ ] Skill operates on described exception-handling intent (at planning or pre-implementation time) -- input is a description of what the developer intends to catch and why; skill does not require code before proceeding
- [ ] For each described exception site, skill asks first: "What happens if you don't catch this?" before recommending any handling
- [ ] Skill classifies each exception into one of three categories: `SURFACE` (let it propagate), `LOG AND RETHROW` (observe but do not swallow), `HANDLE` (genuine recovery is possible and defined)
- [ ] `HANDLE` verdict requires the developer to state: what concrete recovery action will be taken, and how that recovery will be tested -- skill withholds `HANDLE` classification until both are stated
- [ ] Skill refuses to approve a `HANDLE` verdict for any catch that targets a broad base type (e.g., `Exception`, `Error`, `std::exception`) without a specific recovery action or re-raise
- [ ] Over the course of a session covering all three verdict types, all three C2 principles (`DontCatchExceptions`, `LetItCrash`, `FailFast`) appear as named rationale at least once
- [ ] Skill explicitly states: "An unhandled exception that crashes is more useful than a handled exception that hides a bug"
- [ ] Skill is added alongside `code-quality` in the session-bootstrap dispatch table row for "writing or reviewing code" (not as a separate exclusive trigger)

---

### Story 5: Greenfield Project Bootstrapping Skill

**Title:** Greenfield Project Bootstrapping Skill

**Type:** Feature
**Size:** M
**Epic/Component:** Greenfield App Skills
**Priority:** High
**Depends On:** None (consumes `## Domain Model` and `## Architecture Decision` from conversation history if present)

**As a** developer who has a domain model and an architecture decision
**I want to** invoke a skill that writes all project scaffold files to disk automatically
**So that** the repository is immediately ready for GitHub issue-driven development without manual file creation

#### Acceptance Criteria

- [ ] Skill reads `## Domain Model` and `## Architecture Decision` from conversation history automatically; if the most recent Architecture Decision block does not specify a stack, skill asks once before generating any file
- [ ] Supported stacks: Python, TypeScript/Node.js, Rust, Go, C#, C++, C/embedded C. Any other stack produces: "Stack [X] is not in the supported list. Supported: Python, TypeScript/Node.js, Rust, Go, C#, C++, C/embedded C."
- [ ] Skill writes `.gitignore` to disk appropriate for the chosen stack (stack-specific entries, not generic)
- [ ] Skill writes `README.md` to disk seeded from the domain model; README includes: project name, one-paragraph purpose, prerequisites, and a "how to run" section
- [ ] Skill writes `.github/workflows/smoke.yml` to disk: a GitHub Actions workflow that checks out the repo, installs/builds for the chosen stack, runs the hello world entry point, and exits non-zero if the hello world fails
- [ ] Skill writes three issue templates to disk at `.github/ISSUE_TEMPLATE/`: `bug_report.md`, `user_story.md` (matching the story format in this repo's plan.md), and `spike.md`
- [ ] Skill writes a hello world entry point to disk at the conventional path for the chosen stack (e.g., `main.py`, `src/main.ts`, `src/main.rs`, `main.go`, `Program.cs`, `main.cpp`, `main.c`); it prints one line containing the project name and exits 0
- [ ] The generated hello world entry point is syntactically valid and executes successfully for the chosen stack (verified by running it locally in the skill session before emitting `## Bootstrapped Files`)
- [ ] All written file paths are listed in a `## Bootstrapped Files` summary block emitted at the end of the skill run
- [ ] No file content is printed to the conversation as a code block requiring manual copy-paste; all files are written via tool calls

---

## Implementation Notes

*Developer Amigo findings from Discovery + Refinement. These inform todo planning but do not belong in the Feature Specification.*

### Skill Architecture Constraints

- Every skill file must satisfy the 5-element anatomy: FRONTMATTER, IRON LAW, ANNOUNCEMENT, GATE FUNCTION, RATIONALIZATION TABLE (source: `skills/writing-skills/SKILL.md`).
- Every non-trivial rule must answer: Context, Forces, Solution, Consequences (Alexandrian Pattern Form).
- Story 3 is a **reference doc**, not a standalone skill. The 1% gate does not apply to reference docs. The defer-decision logic is embedded in architecture and brainstorming flows.

### Files to Create / Modify

| Story | New Files | Modified Files |
|-------|-----------|----------------|
| Story 1 | `skills/greenfield-discovery/SKILL.md`, `skills/greenfield-discovery/references/DOMAIN_MODEL_SCHEMA.md` | `skills/session-bootstrap/SKILL.md`, `skills/session-bootstrap/references/SKILL_DISPATCH_TABLE.md` (all 5 entries) |
| Story 2 | `skills/greenfield-architecture/SKILL.md` | (loads DECISION_DEFERRAL.md from Story 3) |
| Story 3 | `skills/brainstorming/references/DECISION_DEFERRAL.md` | `skills/brainstorming/SKILL.md` (Phase 3 link), `skills/greenfield-architecture/SKILL.md` (load reference) |
| Story 4 | `skills/exception-philosophy/SKILL.md` | `skills/session-bootstrap/SKILL.md` (add alongside code-quality row) |
| Story 5 | `skills/greenfield-bootstrap/SKILL.md`, `skills/greenfield-bootstrap/references/STACK_TEMPLATES.md` | None |

### Domain Model Block Schema

Minimum required fields (defined in Story 1's `DOMAIN_MODEL_SCHEMA.md`):
- `Problem`: one-paragraph description of the problem being solved
- `Users`: who the primary users are
- `Core Entities`: the main domain objects/operations
- `Success Criteria`: what done looks like from the user's perspective
- `Open Questions`: items flagged `[UNCLEAR:]` during the interview

When multiple `## Domain Model` blocks exist in conversation history, the most recent is authoritative.

### Bounded Stack Templates (Story 5)

Each supported stack requires: `.gitignore` entries, hello world entry point (path + content), and CI build/run steps.

| Stack | Hello World Path | CI Build Step | CI Run Step |
|-------|-----------------|---------------|-------------|
| Python | `main.py` | `pip install -r requirements.txt` | `python main.py` |
| TypeScript/Node.js | `src/main.ts` | `npm install && npm run build` | `node dist/main.js` |
| Rust | `src/main.rs` | `cargo build` | `cargo run` |
| Go | `main.go` | `go build ./...` | `go run main.go` |
| C# | `Program.cs` | `dotnet build` | `dotnet run` |
| C++ | `main.cpp` | `cmake -B build && cmake --build build` | `./build/hello_world` |
| C/embedded C | `main.c` | `gcc main.c -o hello_world` | `./hello_world` |

Unsupported stacks: return the unsupported message immediately, write no files.

### Test Fixtures Needed (per story)

- **Story 1:**
  - Fixture prompt: "I want to build a mathematical model simulator"
  - Fixture doc: short whitepaper excerpt (to be authored as test artifact)
  - Contradiction fixture: "target users are children under 10 AND power users needing API access" (triggers `[UNCLEAR:]`)

- **Story 2:**
  - Fixture `## Domain Model` for the simulator domain
  - Fixture for no-domain-model path (bare invocation)
  - Three low-familiarity fixtures: "I've never used it", "I want to try it", "I don't know the syntax"

- **Story 3:**
  - Fixture A (produces DEFER): "Should I use an ORM or raw SQL?"
  - Fixture B (produces DECIDE NOW): "What is the primary programming language for this project?"
  - Fixture C (produces UNCLEAR): a question with contradictory diagnostic answers

- **Story 4:**
  - Fixture 1 (SURFACE): describing a catch that swallows a network timeout silently
  - Fixture 2 (LOG AND RETHROW): describing a catch that logs and re-raises a database error
  - Fixture 3 (HANDLE): describing a catch for file-not-found with a specific fallback path
  - Fixture 4 (broad base type refusal): describing a catch of `Exception` with no recovery
  - Fixture 5 (composite, multi-step): covers all three verdicts in one session to verify all three C2 citations appear

- **Story 5:**
  - Fixture A: full context present (domain model + architecture decision with Python stack)
  - Fixture B: stack absent (domain model present, no architecture decision)
  - Fixture C: both absent (bare invocation)
  - For each supported stack: run fixture A with that stack and verify files exist + hello world executes

### Session-Bootstrap Dispatch Table Entries (all owned by Story 1)

New rows to add:

| Task type | Skills to add |
|-----------|---------------|
| Starting a new project from scratch | `greenfield-discovery` |
| Choosing a language, runtime, or framework for a new project | `greenfield-architecture` |
| Bootstrapping a new project repo after domain model + architecture decision | `greenfield-bootstrap` |
| Writing or reviewing code | add `exception-philosophy` alongside existing `code-quality` |

Note: `defer-decision` has no dispatch row -- it is embedded, not invoked.
