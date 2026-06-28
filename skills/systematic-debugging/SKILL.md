---
name: systematic-debugging
license: MIT
description: Use when encountering any bug, test failure, build error, or unexpected behavior.
---


# Instructions for Agent

## How This Skill is Invoked

This skill is **mandatory before proposing any fix**. It applies whenever you encounter:
- A test failure, build error, or CI failure
- Unexpected rendering or application behavior
- Anything the user describes as "broken"

When activated, announce: **"I am using the systematic-debugging skill to [brief description of issue]."**

---

## Iron Law

```
YOU MUST INVESTIGATE ROOT CAUSE BEFORE PROPOSING ANY FIX.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the systematic-debugging skill to [brief description of issue]."

---

## Canary

```
CANARY: systematic-debugging loaded. Issue: [name it]. No fix before root cause.
```

---

## BEFORE PROCEEDING

1. The full error output has been read completely -- not just the last line
2. The failure reproduces consistently with identified reproduction steps
   **Note for runtime behavior bugs:** "reproduction steps" means the observation artifact returned by the researcher agent -- not compiler output, static analysis output, or test runner output.
3. I can state: "The root cause is X because Y" with evidence

[+] All met -> proceed
[-] Any unmet -> continue Phase 1 investigation; do not proceed

---

## When to Use

Use this skill for every one of these situations:

- Test failures (unit, integration, visual regression)
- Build failures (cmake, clang, linker errors)
- Unexpected rendering or application behavior
- Visual regression test failures
- CI pipeline failures
- Performance problems
- Anything the user describes as "broken"

**Use this skill especially** when under time pressure, when "one quick fix" seems obvious, when you've already tried a fix that didn't work, or when you don't fully understand the issue. These are exactly when the iron law is most needed -- and most likely to be skipped.

---

## The Four Phases

**Important scope boundary:** A request to "debug" or "investigate" is a request for root cause analysis and a findings report -- NOT a request to fix. Present your findings and wait for explicit instruction before applying any fix. This applies even when the fix seems obvious.

Each phase MUST be completed in order.

### Phase 0: Write the Problem Down First

**First: verify your test runner current working directory (CWD).** Run `pwd` and confirm it matches the required execution directory (e.g., `.../build` for `./tests/ParticleViewerTests`). CWD mismatch is the most common source of false test failures -- a failing test caused by wrong CWD is not a regression and requires no fix.

Before touching any other tool, write one precise sentence describing the failure: what is failing, what was expected, and what actually happened. Vague problem statements produce vague investigations. If you cannot write the sentence, you do not yet understand the problem well enough to investigate it.

See `references/DEBUGGING_TACTICS.md` for the full Feynman Algorithm and structured tactic selection.

### Phase 1: Root Cause Investigation

**Runtime behavior bug:** any reported failure where the symptom can only be observed by running the application -- not by reading source code. If the user describes what they SEE, HEAR, or EXPERIENCE in the running application, it is a runtime behavior bug regardless of what the source code says.

An **observation artifact** is output produced by the running application itself -- a screenshot of the rendered user interface (UI) or a log excerpt from an active process -- NOT compiler output, static analysis output, code review findings, or textual descriptions written by an agent. An observation artifact must be shown inline (in the response or as an attached file), not described by text alone.

For runtime behavior bugs: dispatch a researcher agent with "Build + observe" as a required method to produce an observation artifact that captures the reported symptom. Move to Phase 2 only after the observation artifact exists and the reported symptom is visible in it. Observation of the failure IS the reproduction step for this class of bug -- source code analysis is not.

If the researcher returns INCONCLUSIVE, escalate to the user before continuing. Do not substitute code analysis for the missing observation artifact.

The existing Phase 1 BEFORE PROCEEDING items 1-3 and the global BEFORE PROCEEDING items 1-3 still apply to runtime behavior bugs in addition to this gate -- they are cumulative, not alternative. For item 2 in both blocks, "reproduction steps" means the observation artifact from the researcher. Items 1 and 3 apply as stated.

- Read the error message **completely** -- do not skim the last line and assume you understand it
- Reproduce consistently -- what exact steps trigger the failure?
- Check recent changes -- `git diff`, recent commits -- what changed?
- For **build errors**: read the FULL compiler output, not just the first error
- For **test failures**: read the FULL test output; run the specific failing test in isolation
- For **visual regression failures**: examine the diff image, compare pixels
- For **CI failures**: reproduce locally with the equivalent command before touching code

BEFORE proceeding to Phase 2, verify:
1. The error message has been read completely.
2. The failure reproduces consistently with identified reproduction steps.
   **Note for runtime behavior bugs:** "reproduction steps" means the observation artifact returned by the researcher agent -- not compiler output, static analysis output, or test runner output.
3. You can state: "The root cause is X because Y."

[+] All 3 met -> proceed to Phase 2
[-] Any unmet -> continue Phase 1 investigation; do not proceed

### Phase 2: Pattern Analysis

- Find working examples of similar code in the codebase
- Compare working vs broken -- list every difference, however small
- Read reference implementations COMPLETELY (don't skim)
- Understand ALL dependencies before proposing changes

### Phase 3: Hypothesis and Testing

- Form ONE hypothesis: "I think X is the root cause because Y"
- Make the SMALLEST possible change to test that hypothesis
- One variable at a time -- do not bundle multiple changes
- If it didn't work: form a NEW hypothesis; do not pile more fixes on top of the failed attempt

### Phase 4: Implementation

**GATE: Phase 4 is an implementation step. `systematic-debugging` alone does not authorize touching files.**
Load `subagent-driven-development` before creating a worktree or editing any file. Do not proceed past this gate until that skill is active.

- Fix the root cause, not the symptom
- Write a failing test that reproduces the issue first (see `testing` skill)
- ONE change at a time
- Verify the fix resolves the issue
   **Note for runtime behavior bugs:** "Verify the fix resolves the issue" requires an observation artifact from the running application (as defined in Phase 1 above), not only a passing test. The observation artifact must show the reported symptom is absent.
- Check if the same pattern exists elsewhere in the codebase

---

## The 3-Strikes Architecture Rule

If 3 or more fix attempts have failed: **STOP immediately. Do not attempt a 4th fix.**

Examine whether the approach is architecturally wrong before continuing. Common signals:
- Each fix reveals new coupling in a different place
- Fixes require "massive refactoring" that keeps expanding
- Each fix creates new symptoms elsewhere

**Discuss with the user before attempting more fixes.** The problem is likely not what you think it is.

---

## Red Flags -- STOP

If you find yourself thinking any of the following, **STOP and return to Phase 1**:

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "It's probably X, let me fix that"
- "Add multiple changes, run tests, see what sticks"
- "I don't fully understand but this might work"
- "I've already tried 2 things, one more fix won't hurt"
- "Let me just rerun the test" (for a failing test -- rerunning without understanding = ignoring root cause)
- "It works on my machine" (still needs root cause)
- "CI must have a glitch" (still needs root cause)
- "The Flatpak environment must be doing something weird" (still needs systematic investigation)
- First response to a runtime behavior bug report is code reading -- **STOP. Dispatch a researcher agent with "Build + observe" required. Source code cannot substitute for the observation artifact.**
- Declaring root cause for a runtime behavior bug without an observation artifact from the running application -- **STOP. "The code shows X" is a theory. The observation artifact from the running application is required before Phase 2.**
- "What the user is seeing is correct behavior" / "this is expected behavior" as a response to a user-reported runtime behavior bug -- **STOP. The running application is the ground truth for what the user observes, not the source code. Return to Phase 1 and dispatch the researcher.**
- About to apply a fix (Phase 4) without loading `subagent-driven-development` -- **STOP. Phase 4 is an implementation step. Load `subagent-driven-development` before creating a worktree or touching any file.**

**All of these mean: STOP. Return to Phase 1.**

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Issue seems simple, don't need the process" | Simple issues have root causes too. The process is fast for simple bugs. |
| "Emergency, no time for process" | Systematic debugging is FASTER than guess-and-check thrashing. |
| "Just try this first, then investigate" | First fix sets the pattern. Do it right from the start. |
| "I'll write the test after confirming the fix works" | Untested fixes don't stick. A test first proves the fix actually resolves the issue. |
| "Multiple fixes at once saves time" | Can't isolate what worked. Creates new bugs. |
| "I've already looked at it, I know the problem" | Looking at symptoms != understanding root cause. |
| "The test is flaky, just rerun it" | Flaky = non-determinism = root cause needed. |
| "One more fix attempt" (after 2+ failures) | 3+ failures = architectural problem. Question the approach. |
| "I found it -- patching it now" | "Debug" means investigate and report. It does not mean fix. Present findings, wait for instruction. |
| "I already started debugging before loading this skill -- I'll use it from here" | Retroactive skill load violates the read-before-act Iron Law. Any investigation performed before loading this skill is tainted by unverified assumptions. **STOP. Restart from Phase 0 with this skill active.** |
| "The user confirmed this behavior works" | User confirmation is not empirical verification. Exercise the behavior yourself in the target environment and record the output. "It worked for them" is a second-hand report, not evidence. Run the gate. Show the output. |
| "The code shows the behavior is correct -- the user must be misreading the output" | Source code describes programmer intent; the running application produces what the user observes. For runtime behavior bugs, the running application is the ground truth. Dispatch the researcher with "Build + observe" required. |
| "Reading the relevant code is faster than running the app" | Speed does not matter if the investigation is wrong. Code reading for a runtime behavior bug is theorizing. The observation artifact determines Phase 2 scope. Dispatch the researcher. |
| "The fix is small -- I don't need to load `subagent-driven-development`" | Fix size is irrelevant to the Phase 4 gate. Phase 4 is an implementation step regardless of scope. Load `subagent-driven-development` before creating a worktree or editing any file. No exceptions. |

---

## Project-Specific Commands

For Particle-Viewer debug commands (build, test filter, visual regression diffs, CI reproduction), see `references/PV_DEBUG_REFERENCE.md`.

---

## Integration

- `testing` skill -- for writing the failing test that reproduces the issue (Phase 4)
- `verification-before-completion` skill -- for verifying the fix actually resolved the issue before claiming done

---

## Multi-Component Debugging

For multi-component failures (OpenGL, SDL3, shader, parser, UI), use the Layer Boundary Isolation Protocol and instrumentation template in `references/MULTI_COMPONENT_DEBUGGING.md`.

---

## HeisenBug Patterns in C++

For the full HeisenBug cause/symptom/investigation table and investigation checklist, see `references/CPP_HEISENBUG_PATTERNS.md`.

A HeisenBug is a bug that disappears or changes behavior when you attempt to observe or isolate it. If a bug vanishes under investigation: load `references/CPP_HEISENBUG_PATTERNS.md` and work through the table before declaring it resolved.
