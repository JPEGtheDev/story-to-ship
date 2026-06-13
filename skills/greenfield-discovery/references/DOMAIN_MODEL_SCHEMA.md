# Domain Model Schema

Reference for the `## Domain Model` block produced by the `greenfield-discovery` skill.
Every field marked Required MUST contain project-specific content. Placeholder text is prohibited.

---

## Field Definitions

### Problem
**Required.** One paragraph describing the specific problem this project solves.
- Name who experiences the problem, when it occurs, and what the consequence is of it going unsolved.
- BAD: "This project solves a problem in the simulation domain." (placeholder)
- GOOD: "Researchers running N-body simulations must manually re-enter initial conditions for every scenario. This creates a high-friction loop where exploring parameters requires programming effort rather than scientific reasoning."

### Users
**Required.** Named description of the primary user roles and their relationship to the problem.
- Name roles explicitly. Do NOT write "end users" or "people" -- those are placeholders.
- State what users currently do in place of the solution (workaround, existing tool, manual process).
- If multiple user roles exist with different needs, list each separately.
- BAD: "Users who need the system."
- GOOD: "Graduate students and working engineers with strong mathematical backgrounds but limited programming expertise. They currently use custom scripts or spreadsheets to run simulations."

### Core Entities
**Required.** The main domain objects and the operations performed on them.
- Name each entity using domain vocabulary. Do NOT use generic names: Model, Record, Item, User, Thing.
- For each entity, state what is done to it or what it does.
- Format: "EntityName (operation1, operation2, operation3)"
- BAD: "Model, User, Result"
- GOOD: "EquationSet (define, validate, compose, parameterize); InitialCondition (set, vary, compare); Simulation (configure, run, pause, resume); OutputTrajectory (view, plot, export)"

### Success Criteria
**Required.** What done looks like from the user's perspective.
- State observable user outcomes, not implementation milestones.
- Include a measurable threshold where possible (time, count, clicks).
- BAD: "The feature is implemented and working."
- GOOD: "A researcher configures a 3-body gravitational simulation, runs it, and exports a trajectory plot in under 5 minutes without writing code."

### Open Questions
**Optional.** Items flagged `[UNCLEAR:]` during the interview.
- Each entry is one unresolved contradiction or ambiguity discovered during the interview.
- Format: `[UNCLEAR: user stated X AND Y -- these are mutually exclusive because Z. Which is correct?]`
- Write "None" if no contradictions were found.

---

## Completeness Gate

Before producing the `## Domain Model` block, verify all of the following:

1. Problem field names the specific user experience failure -- not a generic description
2. Users field names roles explicitly -- no "end users" or "people"
3. Core Entities uses domain-specific vocabulary -- no generic names (Model, Item, Record)
4. Success Criteria describes an observable user outcome -- not an implementation milestone
5. Any `[UNCLEAR:]` items from the interview are listed in Open Questions

[+] All met -> produce the `## Domain Model` block
[-] Any unmet -> return to the relevant interview question; do not produce the block until resolved
