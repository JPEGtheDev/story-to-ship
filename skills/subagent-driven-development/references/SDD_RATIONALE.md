# Subagent-Driven Development (SDD) Rationale -- Why, Evidence Mandate, Delegation, Anti-Patterns

## Why Subagents Are Mandatory

Using subagents is discipline, not convenience:

- **Main context fills fast.** Once full, early instructions -- including iron laws -- are evicted. Keep context lean.
- **Subagents search without your bias.** They confirm or deny theories precisely because they lack your assumptions.
- **Parallel dispatch is faster.** Five explore agents simultaneously beat five sequential searches.
- **Subagents keep your diff clean.** Exploratory dead-ends and interim summaries never pollute main context.

## Empirical Evidence Mandate

**No theory, assumption, or belief is acceptable as a basis for action. Every claim must be backed by empirical evidence.**

**Acceptable evidence:**
- Code you read yourself -- opened the file, saw the line
- Test output you ran yourself -- executed the command, read the result
- Documentation cross-checked against actual source code
- A/B test results -- implemented both, compared outcomes
- A targeted test written to prove or disprove the theory

**Not acceptable:**
- Memory ("I remember this worked")
- Confidence ("I'm sure the parser handles this")
- Assumption ("It should work because Y")
- Prior success ("It worked last time")

If you cannot point to a specific file, line, or test run -- dispatch a subagent.

## Red Flags -- STOP

See the canonical Red Flags table in `../SKILL.md`.

## Delegation Quality Rules

- **One clear objective per subagent** -- no multi-part briefs
- **Assign Problems Not Tasks:** delegate the outcome, not the steps -- see the `writing-plans` skill -- 'Assign Problems Not Tasks' principle.
- **State the return format explicitly** -- tell it exactly what to give back
- **Provide complete context** -- subagents are stateless
- **Fresh context per task** -- never share session history; it contaminates the subagent's search
- **Accept findings unless they conflict with evidence you verified yourself**
- **If a subagent finds something unexpected: treat it as a hypothesis; verify before acting**

## Anti-Patterns

| Anti-pattern | Why it fails |
|---|---|
| "I'll check this myself" (for 5+ files) | Fills context, biased by assumptions |
| Skipping Stage 1 review because "it looks right" | Spec gaps ship; quality review doesn't catch them |
| One agent reviewing multiple large files | Coverage is shallow; 1 per file is the rule |
| Acting on subagent findings without verifying | Subagents can be wrong -- findings are hypotheses |
| Dispatching without a clear return format | Agent returns noise |
| Sharing full session history as context | Contaminates search; subagent inherits your assumptions |
| Reporting DONE before 2-stage review | Code exists; correctness unverified |
