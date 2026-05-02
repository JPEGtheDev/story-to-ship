---
name: summarization
license: MIT
description: Use when summarizing external resources (articles, web pages, local files) to extract knowledge and lessons.
---

## Iron Law

```
NEVER SUMMARIZE WITHOUT THE SOURCE IN CONTEXT.
DISPATCH ALL THREE METHODS. SYNTHESIZE AFTER ALL THREE RETURN.
DO NOT WRITE OUTPUT UNTIL THE QUALITY GATE RUNS.
```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST dispatch all three method agents and wait for all three results before dispatching the synthesizer. No exceptions.

**Announce at start:** "I am using the summarization skill to extract knowledge from [source title]."

---

## Pipeline

6 agents run in fixed sequence:

| Step | Agent | Runs when |
|------|-------|-----------|
| 1-3 | Abstractive, Extractive, SAAC | Parallel -- after source is in context |
| 4 | Synthesizer | After all 3 method agents return |
| 5 | Claim Enrichment | After synthesizer writes temp file |
| 6 | Quality Evaluator | After claim enrichment writes enriched temp file |

Partial failure: 1 of 3 methods fails -> synthesizer notes the gap and proceeds. 2+ fail -> halt and report blocked.

---

## BEFORE PROCEEDING

Before dispatching any agent, verify:

1. Source content is in context -- pasted, fetched, or read from file. If absent: read or fetch the source now. Do not dispatch until source is in context.
2. Output path status is known: explicit path provided, directory provided (auto-derive filename), or nothing provided (ask user for directory after summary completes -- not before).
3. `scratch/summaries/` exists for the temp file.

✓ All met -> dispatch agents 1-3 in parallel
✗ Source missing -> fetch or read the source. Do not dispatch.
✗ Output path unknown -> note it; ask user after summary completes.

---

## Canary

Before dispatching the synthesizer, state:

```
Method agents complete: Abstractive [pass/fail], Extractive [pass/fail], SAAC [pass/fail]
```

This signals all three gates were checked before synthesis. It does not prove method output quality.

---

## Dispatch Instructions

See `references/PIPELINE.md` for per-agent prompt structure, variable fill-in, and partial-failure handling.

---

## Output Path Resolution

| Situation | Action |
|-----------|--------|
| Explicit path provided | Use it |
| Directory only, no filename | Kebab-case source title + `.md` in that directory |
| Nothing provided | Ask for directory after summary completes; auto-derive filename |

Auto-derive rule: "Test Frameworks Overview" -> `test-frameworks-overview.md`

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Two of the three methods returned, good enough" | All three must return before dispatching the synthesizer. One missing method = incomplete synthesis. Wait or halt. |
| "The source was in context from a prior message" | Re-read or re-fetch the full source now. Partial context produces partial summaries. |
| "I'll derive the output path without asking" | If no path and no directory was given: ask the user after summary completes. Do not invent a path. |
| "The temp file is good enough, skip quality" | The quality gate is mandatory. Temp file is for review only. Final output requires the quality agent to run. |
| "Quality found minor issues, skip the revision cycle" | One revision cycle is allowed and required when quality flags issues. Run it before writing final output. |
| "The source is short, all three methods will produce the same output" | Method diversity is the point. Overlap is informative. Run all three regardless of source length. |

---

## Red Flags -- STOP

- About to dispatch the synthesizer without all 3 method results in hand -- **STOP. Wait for all three. Note any failed agent before proceeding.**
- About to write output to a path the user did not specify or confirm -- **STOP. Ask for the directory after summary completes.**
- Source content is a URL or filename but not yet fetched or read -- **STOP. Fetch or read the source before any dispatch.**
- Quality agent returned failures and revision cycle has not run -- **STOP. Run the revision cycle. Then write final output.**
- About to skip the temp file step -- **STOP. Write to `scratch/summaries/temp-[title].md` before dispatching quality.**
- Canary line not yet stated and about to dispatch synthesizer -- **STOP. State the method agent completion status first.**

---

## Related Skills

- `dispatching-parallel-agents` -- parallel dispatch protocol for agents 1-3
- `subagent-driven-development` -- agent dispatch, result collection, and 2-stage review
