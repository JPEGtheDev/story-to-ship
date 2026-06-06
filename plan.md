# Greenfield App Skills -- Planning

## Stories

### Story 1: Greenfield Discovery Skill

**Title:** Greenfield Discovery Skill

**Type:** Feature
**Size:** M
**Epic/Component:** Greenfield App Skills
**Priority:** High
**Depends On:** None

**As a** developer starting a new project from scratch
**I want to** invoke a skill that interviews me about my idea and then asks for any supporting documentation
**So that** Claude has a structured domain model to reason from before recommending architecture or writing any code

#### Acceptance Criteria

- [ ] Skill asks a structured set of questions to capture: what problem is being solved, who the users are, what the core entities/operations are, and what success looks like
- [ ] After the interview, skill explicitly asks: "Do you have any supporting documentation, whitepapers, or domain references I should read?" and waits for a response before proceeding
- [ ] If docs are provided, skill reads them and merges extracted domain concepts with interview answers into a single domain summary block
- [ ] Domain summary block is labelled `## Domain Model` and is emitted to the conversation before the skill ends
- [ ] Skill surfaces `[UNCLEAR:]` labels for any interview answer that is ambiguous or contradictory
- [ ] Running the skill with a prompt like "I want to build a mathematical model simulator" produces a populated domain summary, not a generic placeholder

---

### Story 2: Greenfield Architecture & Stack Advisor Skill

**Title:** Greenfield Architecture & Stack Advisor Skill

**Type:** Feature
**Size:** M
**Epic/Component:** Greenfield App Skills
**Priority:** High
**Depends On:** None (optionally consumes domain model + architecture decision from prior greenfield skills if present)

**As a** developer who has a domain model or general idea
**I want to** invoke a skill that recommends a language, stack, and initial architecture
**So that** I start building on a foundation that fits the problem and my own ability to maintain it, not just Claude's default preference

#### Acceptance Criteria

- [ ] Skill accepts a domain model (from greenfield-discovery) OR asks a minimal set of context questions if no domain model is present
- [ ] Skill asks the user to rate familiarity with candidate languages/stacks before making a recommendation
- [ ] Recommendation output includes: primary language, runtime/framework, key dependencies, and a one-sentence rationale for each choice
- [ ] Recommendation explicitly identifies which decisions are being deferred and why (referencing the defer-decision skill)
- [ ] Skill produces an `## Architecture Decision` block covering: language, runtime, persistence, and API boundary (or marks each as `DEFERRED` with a condition for revisiting)
- [ ] If the user's familiarity is low with the recommended stack, skill flags this and asks if they want an alternative

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

- [ ] Skill asks three diagnostic questions: (1) Does making this decision now constrain anything that isn't yet built? (2) Can this decision be reversed cheaply in two sprints? (3) Does deferring this decision block the current vertical slice?
- [ ] Skill outputs one of three verdicts: `DECIDE NOW`, `DEFER -- revisit when [condition]`, or `[UNCLEAR:] -- answer [question] before deciding`
- [ ] `DEFER` verdict includes a concrete re-entry condition (measurable event, not "when the time is right")
- [ ] Skill cites at least one named principle per verdict: YAGNI for `DEFER`, or a named risk for `DECIDE NOW`
- [ ] Skill explicitly refuses to output `DEFER` when deferring would require a significant rewrite of already-built code

---

### Story 4: Exception Philosophy Skill (Skeptic Mode)

**Title:** Exception Philosophy Skill

**Type:** Feature
**Size:** S
**Epic/Component:** Code Quality / Exception Handling
**Priority:** Medium
**Depends On:** None

**As a** developer writing or reviewing exception handling code
**I want to** invoke a skill that challenges each catch block and asks "do you actually need to handle this?"
**So that** real failures surface as crashes or logs rather than being silently swallowed, and I don't build false safety nets that hide production problems

#### Acceptance Criteria

- [ ] Skill acts as a skeptic: for each exception or error-handling site presented, it asks "what happens if you don't catch this?" before recommending any handling
- [ ] Skill classifies each exception into one of three categories: `SURFACE` (let it crash/propagate), `LOG AND RETHROW` (observe but don't swallow), `HANDLE` (genuine recovery is possible and defined)
- [ ] `HANDLE` verdict requires the developer to state: what concrete recovery action will be taken, and how this will be tested
- [ ] Skill refuses to approve a catch block that catches a broad base type without a specific re-raise or log-and-rethrow
- [ ] Skill references C2 `DontCatchExceptions`, `LetItCrash`, and `FailFast` as named rationale
- [ ] Skill explicitly states: "An unhandled exception that crashes is more useful than a handled exception that hides a bug"

---

### Story 5: Greenfield Project Bootstrapping Skill

**Title:** Greenfield Project Bootstrapping Skill

**Type:** Feature
**Size:** M
**Epic/Component:** Greenfield App Skills
**Priority:** High
**Depends On:** None (optionally consumes domain model + architecture decision if present)

**As a** developer who has a domain model and an architecture decision
**I want to** invoke a skill that bootstraps the project repo with a gitignore, README, CI smoke test, issue templates, and a hello world entry point
**So that** the repository is immediately ready for GitHub issue-driven development without manual setup overhead

#### Acceptance Criteria

- [ ] Skill produces a `.gitignore` appropriate for the chosen stack -- if stack is unknown, skill asks before generating
- [ ] Skill produces a `README.md` seeded from the domain model summary or from a minimal inline interview if no prior context exists; README includes: project name, one-paragraph purpose, prerequisites, and a "how to run" section
- [ ] Skill produces a GitHub Actions workflow at `.github/workflows/smoke.yml` that: checks out the repo, installs/builds, and runs the hello world entry point -- workflow exits non-zero if the hello world fails
- [ ] Skill produces GitHub issue templates at `.github/ISSUE_TEMPLATE/`: `bug_report.md`, `user_story.md` (in this project's story format), and `spike.md`
- [ ] Skill produces a hello world entry point in the correct file for the chosen stack that prints one line confirming the project name and exits 0
- [ ] If stack was not provided by an upstream skill, skill asks before generating any file
- [ ] All generated files are listed in a `## Bootstrapped Files` summary block at the end of the skill run
