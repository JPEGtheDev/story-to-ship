# SDD Rationale -- Why, Evidence Mandate, Delegation, Anti-Patterns, Red Flags

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

These thoughts mean stop immediately:

| Thought | Required action |
|---------|----------------|
| "I think the issue is..." | Dispatch explore agent -> read the actual code |
| "I dispatched a subagent -- I'll also work on this while waiting" | STOP. The only permissible next call is read_agent. "I'll wait" is a binding constraint, not a statement of intent. |
| "This should work because..." | Run it. Read the output. |
| "I'm confident that..." | State the evidence, or dispatch to get it |
| "It probably passes..." | Run the test suite |
| "I remember that..." | Memory is always unverified -- dispatch |
| "Based on how it usually works..." | Dispatch to confirm the actual behavior |
| "Dispatching a file-modifying agent without creating a worktree first" | STOP. Create the worktree and load `using-git-worktrees` before dispatch. |
| "About to create a worktree without `using-git-worktrees` loaded" | STOP. Load `using-git-worktrees` first -- every time, without exception. |
| "A template exists but I'll build the prompt manually" | STOP. Use the pre-built template from `.claude/agents/`. Do not reinvent it. |
| "These two todos form a 'Phase N' -- I'll dispatch them together" | STOP. Phase is a planning concept, not a dispatch unit. Split unconditionally before dispatch. |

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
