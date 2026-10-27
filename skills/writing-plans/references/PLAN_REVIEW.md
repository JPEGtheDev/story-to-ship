# Plan Review Reference

The plan-review dispatch and the Review-Round Cap, read before presenting a plan with 2+ todos or an architectural decision.

**If plan.md contains `## Feature Specification` (Discovery ran):**
Invoke the `three-amigos` skill for a Refinement review. Three amigos review replaces the Skeptic for Discovery features.

**Otherwise (no Discovery):**
Dispatch BOTH agents in parallel: a **Skeptic Agent** and the **plan-reviewer agent**. Read both verdicts before presenting the plan as final.

The Skeptic Agent prompt is `references/SKEPTIC_PROMPT.md`; pass it to the Skeptic Agent verbatim.

Also dispatch the **plan-reviewer agent** using the `agents/plan-reviewer.md` template, passing it the plan path and a worktree. Its role is complementary to the Skeptic's: the Skeptic finds what is MISSING from the plan; the plan-reviewer judges whether what IS in the plan is sound, correctly sequenced, and enforceable. Both verdicts are mandatory reads before the plan is presented as final -- neither agent substitutes for the other.

### Review-Round Cap

Adversarial plan review is capped at round 3. Past round 3, OR as soon as plan length exceeds the length of the file(s) it edits, switch the review surface from plan prose to the diff: implement, then review the diff. Do not add more plan-review rounds.

**Self-feeding detector:** a blocking finding located in text written in answer to the previous round -- not in the original plan -- is a manufactured defect. Treat it as the stop signal, not as something to fix with more prose. "Rounds keep finding real defects" and "the review must stop" can both be true at once; the fix is switching surfaces, not adding rounds.

**Permissive-clause closure:** when a review finds an ambiguous or permissive clause, close it by deleting the clause, not rewording it -- rewording can make the bypass easier (e.g. "the user asks" -> "the user directs the change" turned a stretch into a bright-line match). If you must reword, test the new wording against the concrete evasion sentence that exploited the old wording.

**Enforcement is procedural/self-check:** round count > 3 and plan-lines > target-file-lines are both countable from the transcript/plan file. No automated detector exists.
