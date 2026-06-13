# Example Run: Mathematical Model Simulator

Fixture session demonstrating the `greenfield-discovery` skill on the prompt
"I want to build a mathematical model simulator." Verifies AC: domain-specific vocabulary
appears in the `## Domain Model` output (simulator, model, equations, trajectory).

---

## Fixture Prompt

User: "I want to build a mathematical model simulator."

---

## Expected Interview Flow

**greenfield-discovery:** I am using the greenfield-discovery skill to conduct a domain interview for a mathematical model simulator.

What specific problem does this project solve? Who experiences it, and what happens when it goes unsolved?

**User:** Scientists and engineers spend hours manually re-entering parameters into equation solvers every time they want to test a different initial condition. Without a simulator, each scenario requires rewriting code or reconfiguring spreadsheets from scratch.

---

**greenfield-discovery:** Who are the primary users? What is their technical background?

**User:** Graduate students and working engineers in physics, chemistry, and mechanical engineering. They understand the math well but are not expert programmers.

---

**greenfield-discovery:** What are the main things this system tracks, creates, or transforms?

**User:** Mathematical models -- sets of equations with parameters. You run a model against a set of initial conditions and get an output trajectory showing how the system evolves over time.

---

**greenfield-discovery:** What does a user actually DO with those things -- create, run, share, export?

**User:** Define an equation set, set initial conditions, run the simulation, view the output trajectory, and export results to a file or chart.

---

**greenfield-discovery:** What does success look like for a user after they have used this system?

**User:** A researcher can configure a 3-body gravitational simulation, run it, and export a trajectory plot in under 5 minutes -- without writing any code.

---

**greenfield-discovery:** Do you have any supporting documentation, whitepapers, or domain references I should read?

**User:** No.

---

## Expected ## Domain Model Output

```
## Domain Model

**Problem:** Scientists and engineers running N-body simulations and differential equation
models must manually re-enter parameters and rewrite solver code for each scenario they
want to test. This creates a high-friction loop where exploring initial conditions requires
programming effort rather than scientific reasoning -- slowing research iteration and
introducing transcription errors.

**Users:** Graduate students and working engineers in physics, chemistry, and mechanical
engineering. Strong mathematical background; limited programming expertise. Current workflow:
custom scripts or spreadsheets that are fragile, non-reproducible, and require re-entry for
each parameter change.

**Core Entities:** EquationSet (define, validate, compose, parameterize); InitialCondition
(set, vary, compare across runs); Simulation (configure, run, pause, resume); OutputTrajectory
(view, plot, export); SimulationRun (record, replay, compare with other runs).

**Success Criteria:** A researcher configures a 3-body gravitational simulation, runs it, and
exports a trajectory plot in under 5 minutes without writing code. Multiple initial condition
scenarios can be compared side-by-side in the same session.

**Open Questions:** None.
```

---

## Fixture Verification

This output satisfies the fixture acceptance criterion:

- Domain-specific vocabulary present: simulator, model, equations, trajectory, initial conditions, N-body, EquationSet, InitialCondition, Simulation, OutputTrajectory, SimulationRun
- No generic placeholders: no "the system", "entities", "users", "items", "records"
- Problem field names a specific user experience failure (manual parameter re-entry, transcription errors)
- Users field names roles (graduate students, working engineers) with background context
- Core Entities uses domain vocabulary (EquationSet, Simulation, OutputTrajectory) with operations
- Success Criteria is an observable user outcome with a time bound (under 5 minutes)
- Open Questions is "None" -- no contradictions detected in the fixture session

---

## Contradiction Fixture

To verify `[UNCLEAR:]` detection, use this contradictory input:

User: "Target users are children under 10 AND power users needing API access."

Expected output from greenfield-discovery:

> "[UNCLEAR: you said target users are children under 10 AND power users needing API access -- these appear mutually exclusive because an API-driven interface requires programming knowledge that children under 10 do not have, and a child-appropriate interface would limit the API surface that power users require. Which user population is primary?]"

The skill MUST NOT ask the next interview question until the user resolves this contradiction.
