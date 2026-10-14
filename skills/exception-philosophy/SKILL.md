---
name: exception-philosophy
license: MIT
description: Use when a developer describes an exception handler, catch block, or error-recovery path they intend to write, before any code exists.
---


## Iron Law

```
ASK "WHAT HAPPENS IF YOU DON'T CATCH THIS?" FOR EVERY CATCH SITE BEFORE RECOMMENDING ANYTHING
YOU MUST get that answer first and give a verdict only after it. No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the exception-philosophy skill to challenge whether [site] needs a handler."

Core principle: An unhandled exception that crashes is more useful than a handled exception that hides a bug

Scope: `cpp-safety` owns the C++ destructor try/catch rule. `code-quality` owns the smell checklist on written code. `cpp-patterns` owns C++ and OpenGL error-handling patterns. This skill owns the language-agnostic decision whether to catch at all, at planning time.

---

## BEFORE PROCEEDING

Inputs: a description of each catch site is required. The exception type is required for the broad-type test (ask if absent). The recovery action and its test are required only for HANDLE. Language and code are optional; pasted code is context, never a requirement.

1. Does the description name at least one concrete catch site?
   - [+] -> go to 2
   - [-] -> ask for the site, its exception type, and why the developer wants to catch it. Print no verdict.
2. Has the developer answered "What happens if you don't catch this?" for this site?
   - [+] -> go to 3
   - [-] -> ask the question now. A request to skip it is declined; ask it again. Print no verdict.
3. Is the site inside a destructor body?
   - [+] -> apply the `cpp-safety` skill; stop here.
   - [-] -> go to 4
4. Has the developer named the exception type for this site?
   - [+] -> go to 5
   - [-] -> ask for the type. Print no verdict.
5. Collect three facts. Ask for the type or the re-raise answer if it is missing; ask for recovery details only when the developer claims a recovery, and treat a site with no claimed recovery as "no" without asking. Print no verdict yet.
   - Type: broad (closed list: Exception, Error, Throwable, BaseException, std::exception, catch (...), bare except) or specific.
   - Re-raise: does the catch re-raise after observing?
   - Recovery: did the developer state (a) a concrete recovery action with an observable end state other than "continue", and (b) how that recovery will be tested?
6. Print exactly one line for the site, from this table. Re-raise is checked first, recovery second, and a broad type changes only the last row.

   | Re-raise | Recovery + test | Verdict line |
   |----------|-----------------|--------------|
   | yes | no | `VERDICT: LOG AND RETHROW` (rationale: FailFast); allowed for a broad type |
   | yes | yes | `VERDICT: HANDLE` (rationale: DontCatchExceptions); the stated recovery path is evaluated as HANDLE, any type |
   | no | yes | `VERDICT: HANDLE` (rationale: DontCatchExceptions); a broad type is not refused because a specific recovery and test are stated |
   | no | no, type broad | `VERDICT: HANDLE WITHHELD` (rationale: DontCatchExceptions); refuse HANDLE and offer SURFACE or LOG AND RETHROW |
   | no | no, type specific | `VERDICT: SURFACE` (rationale: LetItCrash); if the developer claims a recovery but names no end state or no test, print `VERDICT: HANDLE WITHHELD` instead, name the missing item, and ask for it |

---

## Rules

**Swallow is not recovery.** Context: any claimed recovery. Forces: "log it and carry on" feels like handling but leaves the program running in an unknown state, which hides the bug. Solution: a recovery MUST end in an observable state other than continuing (a fallback path taken, a retry that is bounded, a value returned that callers can tell apart). Consequences: some benign handlers need a named end state they did not have.

**Broad catch plus re-raise is allowed.** Context: a catch of a broad type at a boundary. Forces: refusing every broad catch would block legitimate logging. Solution: re-raise after observing, and issue LOG AND RETHROW. Consequences: the catch stays but cannot absorb the error.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Just give me the verdict, skip the question" | The answer decides the verdict. Decline and ask it. |
| "A crash looks bad to users" | A hidden bug corrupts data silently. Surface it; handle only with a defined recovery. |
| "I will catch Exception to be safe" | A broad catch with no recovery and no re-raise is refused. Name the specific type. |
| "Logging and continuing is the recovery" | That swallows the error. State an observable end state other than continuing. |
| "I will test the handler later" | HANDLE stays withheld until the recovery test is stated now. |
| "It is only a destructor, nothing can go wrong" | Destructor bodies belong to the `cpp-safety` skill. Defer to it. |

---

## Red Flags -- STOP

- About to recommend a handler before the developer answered the question -- **STOP. Ask "What happens if you don't catch this?" first.**
- Description names no catch site -- **STOP. Ask for the site and its exception type. Print no verdict.**
- Developer asks to skip the question -- **STOP. Decline and ask it.**
- Catch targets a broad base type with no specific recovery and no re-raise -- **STOP. Print `VERDICT: HANDLE WITHHELD` and refuse HANDLE.**
- "Recovery" is only logging, ignoring, or returning a default silently -- **STOP. Treat it as a swallow; ask for an observable end state.**
- About to print `VERDICT: HANDLE` without a stated recovery test -- **STOP. Print `VERDICT: HANDLE WITHHELD` and ask for the test.**

---

## Related Skills

- `cpp-safety` -- destructor try/catch rule; defer destructor sites to it
- `code-quality` -- smell checklist on written code
- `cpp-patterns` -- C++ and OpenGL error-handling patterns
