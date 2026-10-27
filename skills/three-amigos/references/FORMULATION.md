# Formulation -- writing Given/When/Then scenarios

This guidance applies when a criterion or a Feature Specification scenario is written as Given/When/Then. Plain-language criteria stay allowed, and the Feature Specification format does not change. The Proof kinds section applies to every acceptance criterion, Given/When/Then or plain language.

## Formulation

Apply the nine rules below to every scenario written in Given/When/Then form. Each rule has its source and one good-vs-weak pair written in this repo's Discovery vocabulary; example-map terms (R1-E1, verdict, skeptic check) are defined in CEREMONIES.md, Ceremony 1.

1. MUST put only the starting state in a Given step. DO NOT put a user action in a Given step.
   Source: Gherkin reference
   Good: Given plan.md has a `## Discovery Open Items` heading. Weak: Given the owner opens plan.md and clicks Save.

2. MUST name exactly one action or event in each When step, performed by a person or by another system.
   Source: Gherkin reference
   Good: When the synthesis step writes the map. Weak: When the orchestrator reads the map, writes plan.md and commits it.

3. MUST assert something a reader outside the system can see. For a skill or plan file, the observable thing is what a reader of the artifact sees, such as a heading present or absent. DO NOT assert on an internal variable.
   Source: Gherkin reference
   Good: Then plan.md has a `## Discovery Open Items` heading and no `## Feature Specification` heading. Weak: Then the verdict variable equals BACK TO OWNER.

4. MUST group the scenarios that illustrate one business rule together, and each example MUST illustrate only that rule. DO NOT put two business rules in one group.
   Source: Gherkin reference
   Good: One group, "a rule with no example gives BACK TO OWNER", holds examples R1-E1 and R1-E2. Weak: One group holds "a rule with no example gives BACK TO OWNER" and "Questions must be none or a question".

5. MUST keep each scenario to three to five steps. When a scenario has more than five steps, split it or raise its steps to a higher level. This counts steps inside one scenario; it is not the 3-5 acceptance criteria count in the Discovery agenda.
   Source: Gherkin reference
   Good: Given, When, Then for example R1-E1 (three steps). Weak: Twelve steps that walk through every field of the example map in one scenario.

6. MUST move a Given step that every scenario in a group repeats into a Background (a short block of Given steps shared by every scenario in the group), and keep the Background short. DO NOT copy the same Given step into each scenario.
   Source: Gherkin reference
   Good: One Background holds Given plan.md has a `## Discovery Open Items` heading for three scenarios. Weak: The same Given line is copied into each of the three scenarios.

7. MUST replace near-duplicate scenarios with one Scenario Outline (one scenario run once per row of an Examples table) and an Examples table when they differ only in values.
   Source: Gherkin reference
   Good: One Scenario Outline with an Examples table of verdicts READY FOR PLANNING and BACK TO OWNER. Weak: Two scenarios that differ only in the verdict word.

8. MUST describe the behavior a reader gets, not the procedure that produces it. Test each step: if its wording would change when the implementation changes, rewrite it.
   Source: Writing better Gherkin
   Good: Then plan.md has no `## Feature Specification` heading while the verdict is BACK TO OWNER. Weak: Then the synthesis step calls the write function after the skeptic check.

9. MUST write steps as business facts. DO NOT write keystrokes, field positions or button names in a step; when the scenario is automated, they belong in the step definitions (the code that runs each step).
   Source: Writing better Gherkin
   Good: Given the owner has answered every open question. Weak: Given the owner clicks the Verdict dropdown and selects BACK TO OWNER.

## Proof kinds

Every acceptance criterion is proven by one of three proof kinds. A criterion with no stated proof kind is proven by an automated test. Skill and prompt text is documentation, not shipped code.

1. Automated test -- a test kept in the repository that fails before the change and passes after it. It applies to a criterion about behaviour of shipped code (anything a user or another program runs, such as a hook, a tool script or a CI step). Its proof is the test name and its run output.
2. Documentation evidence -- it applies to a criterion about the text of a document or skill file. Its proof is the file and line, or a command whose output shows the text.
3. Throwaway spike -- it applies to a criterion about a one-off investigation whose code is discarded. Its proof is the run command and its output, kept in the pull request or, when there is no pull request, in the issue; the spike code is not merged.

A criterion about behaviour of shipped code still requires an automated test; "the test is hard to write" is not a reason to choose another proof kind.
A criterion that fits none of the three proof kinds is proven by an automated test.
A criterion proven by documentation evidence or a throwaway spike ends with `Proof: documentation` or `Proof: spike`; the label applies to Given/When/Then and plain-language criteria alike.

## Unverified

- BRIEF -- the Behavior-Driven Development (BDD) book names a guideline set called BRIEF; its expansion is unconfirmed and no rule here is taken from it.
- Scenario titles -- no source was read, so no title rule is given.

Both items above are unverified and carry no rule in this file.

## Sources

- Gherkin reference (Cucumber)
- Writing better Gherkin (Cucumber)
- The BDD Books - Formulation (contents list only was read)
