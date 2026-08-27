---
name: sprint-runner
license: MIT
description: Use when running a multi-agent pipeline that must follow a declared, replayable JSON spec instead of ad hoc orchestration.
---


## Iron Law

```
YOU MUST NEVER RUN A SPEC WHOSE verifyDigest PATHS ARE NOT STAGED ON DISK, AND YOU MUST NEVER REPORT A HALTED RUN (status: halted -- stopped before finishing) AS A SUCCESSFUL ONE. No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the sprint-runner skill to run [spec name]."

---

## What it is

The sprint engine is a spec-driven multi-agent pipeline executor: a spec is a JSON document declaring an ordered list of steps -- agent, gate, shape, parallel, map, scored-retry, branch -- and the runner executes them through the Workflow tool runtime, dispatching subagents, enforcing gates, spilling oversized outputs, and verifying digests.

Reach for it when multi-agent work must follow a declared, replayable pipeline instead of ad hoc orchestration; skip it for a single dispatch.

---

## Invocation

Invoke the Workflow tool with `scriptPath` set to this skill's base directory plus `/tools/sprint-runner.js`, and the spec as `args`. This skill's base directory is the absolute path shown on the "Base directory for this skill:" line printed when this skill loads. Whether an install ships `tools/` on disk has not been verified by a live run yet -- if `tools/` is absent, report it on the story-to-ship issue tracker.

---

## BEFORE PROCEEDING

`args` is the spec itself (object or JSON string; both accepted). Before invoking:

1. Does the spec validate against `tools/SPEC_SCHEMA.md` (known step kinds, depth <= 3, no reserved segments)?
   - [+] -> proceed
   - [-] -> fix it against `tools/SPEC_SCHEMA.md` first
2. Does every `verifyDigest.path` (path + expected sha256) already exist on disk with matching content?
   - [+] -> proceed
   - [-] -> stage it first; the engine halts on a mismatch rather than creating the file
3. If the spec has an agent step, is `config.spillDir` (the oversized-output write target)'s parent directory writable?
   - [+] -> proceed
   - [-] -> fix `spillDir` first; any agent step's output can exceed the spill threshold
4. After the run returns, is `status` a halt?
   - [+] halted -> the pipeline did NOT complete; report `halt.diagnostic`/`halt.path`, not a success
   - [-] not halted -> report the result normally

[+] All met -> proceed
[-] Any unmet -> resolve first

---

## Deeper reference

Self-contained: the whole engine ships inside `tools/`.

- `tools/README.md` -- running a spec, result map, digest staging
- `tools/SPEC_SCHEMA.md` -- the full spec contract: step kinds, fields, validation rules, including the "Minimal valid spec" smoke test (also in `tools/README.md`).

---

## Red Flags -- STOP

- "The spec is small, skip validation" -- STOP. A one-step spec can still have an unknown step kind or bad predicate; validate against `tools/SPEC_SCHEMA.md` regardless of size.
- "It halted but the last step looked fine, call it done" -- STOP. A halt is not a completion; report `halt.diagnostic` and `halt.path`.
- "Skip staging verifyDigest, it'll just halt cleanly if wrong" -- STOP. A predictable halt still wastes the run; stage it first.
- "The engine will catch a bad `{{...}}` reference" -- STOP. Static validation never scans prompt fields; a bad reference only surfaces at render time, as a halt.
- "The pipeline is simple, skip the minimal-spec smoke test" -- STOP. Run the spend-free smoke test from `tools/SPEC_SCHEMA.md`'s "Minimal valid spec" section first.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I already know the path from last time, no need to check the base directory again" | Each load's base directory reflects that install's actual location; a stale hand-typed path breaks the moment the install location differs |
| "I wrote the spec carefully, I know it's valid" | Careful authoring still misses depth limits and reserved-segment rules; validate structurally regardless |
| "A halted run with good partial results is basically a success" | `status: halted` means the pipeline did not complete; report it as a halt, not a caveated success |
| "The digest check is just a formality" | `verifyDigest` stops the run before it processes wrong or stale content; skipping staging guarantees a halt |
| "spillDir only matters for huge outputs, mine will be small" | Any agent step can exceed the spill threshold; the requirement holds once one exists |

---

## Related Skills

- `subagent-driven-development` -- the runner's agent steps are dispatched subagents; governs dispatch/review
- `using-git-worktrees` -- every dispatched agent step needs its own worktree per that skill's Iron Law; the engine never creates them
