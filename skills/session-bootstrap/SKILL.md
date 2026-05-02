---
name: session-bootstrap
license: MIT
description: Use at the start of every session.
---

## Iron Law

```
READ THE SKILL. THEN ACT. NEVER ACT THEN READ.
```

Violating the letter of this rule is violating the spirit of this rule.

YOU MUST read all required skills before writing any code or sending any plan. No exceptions.
Skills contain rules that change what you do. Reading a skill AFTER acting defeats the purpose.

**Announce at start:** "I am using the session-bootstrap skill to load required skills for this session."

---

## Skill Refresh — Mandatory

**Stale skill context is worse than no skill.** Skills evolve. Context windows truncate. Skills loaded early in a session may no longer be active when you need them.

### When to Reload a Skill

Reload the relevant skill(s) immediately when ANY of these occur:

1. **Picking up a new todo** — reload the skill(s) for that todo's domain before starting work
2. **After 3 user prompts** without a skill reload — reload the skill for whatever you are currently doing
3. **After a user correction or redirect** — the correction is evidence the skill was misapplied or is stale; reload it
4. **After context compaction** — any compaction event requires full skill reload for the active domain

**Announce the reload:** "Reloading `[skill-name]` — [reason: new todo / 3 prompts / correction]."

Do NOT say "I remember the skill content." A remembered skill is an unverified skill. Load fresh.

### `honesty` — Co-Equal Peer Skill

`honesty` is NOT managed by `session-bootstrap`. It is a co-equal peer skill with its own hook injection. The pre-message hook injects the Honesty Gate into every turn automatically. The session-start hook injects the full Honesty Gate at session start.

If neither hook output is visible in context, load `honesty` explicitly before responding. Do NOT proceed with a task-specific skill while honesty content is absent from working context.

---

## On Start — Minimum Skill Loads by Task Type

Before writing code, read the skill(s) relevant to your task. `honesty` is injected by hook — load it explicitly only if hook output is absent.

Before writing code, read the skill(s) relevant to your task. If the task touches multiple
domains, read multiple skills in parallel (they are independent reads).

| If the task involves…                        | MUST read these skills BEFORE acting               |
|----------------------------------------------|----------------------------------------------------|
| Any implementation work                      | `execution`                                        |
| Planning a multi-step task                   | `writing-plans`                                    |
| Unclear approach or design choices           | `brainstorming`                                    |
| Writing or editing code                      | `execution`, `code-quality`                        |
| Writing code with rendering/runtime patterns | `execution`, `code-quality`, `cpp-patterns`        |
| Writing or editing tests                     | `execution`, `code-quality`, `testing`             |
| Writing visual regression tests              | `execution`, `code-quality`, `testing`, `visual-regression-testing` |
| Creating a PR or commit                      | `versioning`, `verification-before-completion`     |
| Finishing / closing a branch                 | `finishing-a-development-branch`                   |
| Requesting code review                       | `requesting-code-review`                           |
| Receiving code review feedback               | `receiving-code-review`                            |
| CI/CD or workflow changes                    | `workflow`                                         |
| Flatpak packaging or GL runtime              | `flatpak`                                          |
| Build system or dependency changes           | `build`                                            |
| Writing or editing documentation             | `documentation`                                    |
| Bug fixes or error resolution                | `execution`, `systematic-debugging`                |
| Any failure or unexpected behavior           | `systematic-debugging`, `verification-before-completion` |
| Dispatching subagents                        | `subagent-driven-development`                      |
| Parallel agent work / A/B testing            | `subagent-driven-development`, `using-git-worktrees` |
| Creating user stories                        | `user-story-generator`, `user-story-estimation`    |
| Creating or editing a skill file             | `writing-skills`, `skill-reviewer`                 |
| Resuming from a prior session with pending SQL todos | `writing-plans`; dispatch Skeptic before first implementation step |
| Schema design, new data structure, or plan with ≥5 implementation items | `brainstorming`, `writing-plans` |
| Auditing communication quality or postmortem | `honesty`, `session-postmortem`                    |
| Any new plan with 2+ todos | `writing-plans`; dispatch Skeptic before first implementation step |
| Auditing or reorganizing a collection of files, tasks, or artifacts with multiple valid structural approaches | `brainstorming`, `writing-plans` |

If unsure, read `code-quality` — it applies to every code task.

**Loading protocol:**
1. Invoke `honesty` first — every session, regardless of task type
2. Identify task type(s) from the table above
3. Load all required skills before writing a single line of code or sending a plan
4. Announce each skill load: "I am using the [skill-name] skill to [purpose]."

## BEFORE PROCEEDING

- [ ] `honesty` invoked first — before any other skill
- [ ] Task type(s) identified from the On Start table above
- [ ] All required skills for this task type loaded (in parallel if multiple domains)
- [ ] Skill load announcement made for each loaded skill
- [ ] `git status` checked in main working tree — if uncommitted changes exist with no active work in progress, identify their source (prior agent? manual edit?), read the diff, then commit or revert explicitly before starting new work. Ghost commits from prior agents are a recurring risk.
- [ ] If resuming a prior session: SQL pending todos checked; Skeptic dispatched before first implementation step
- [ ] Stored memories checked for user-specified model preference overrides — applies to all agent dispatch decisions this session
- [ ] If this task requires reading 3+ files for research or review: an explore or code-review agent is dispatched — NOT done inline
- [ ] Session hooks checked: if sessionStart or userPromptSubmitted hook failed, all skills MUST be invoked manually this session — no auto-loading is available
- [ ] If a hook config fix was committed during this session: that fix is NOT active until the NEXT session. Do NOT claim hooks are working. The CLI reads hooks.json once at session start — in-session commits to hook files do not take effect until the session is restarted.

✓ All met → proceed with session work
✗ Any unmet → complete the unmet step now before writing code or sending a plan

---

## On Finish — Self-Evaluate and Compact

**Self-evaluation fires at session END.** If a major task completes mid-session with no further work planned, treat it as session end and execute On Finish now.

**Before your final message to the user**, execute all of the following:

1. **Read** `.github/skills/self-evaluation/SKILL.md` and follow its steps.
2. **Identify lessons learned** — mistakes made, user corrections, patterns discovered.
3. **Check existing skills** — is the lesson already documented? If yes, skip.
4. **Apply updates** — for High/Medium priority lessons, update the relevant skill file
   and bump its version in the YAML frontmatter. Commit the skill update with the
   session's work.
5. **Compact** — scan any files you touched for bloated comments or duplicated docs.
   Migrate detail to skills/docs and leave 1-line references.
6. **Report** — include a `### Session Self-Evaluation` block in your final message:
   ```
   ### Session Self-Evaluation
   Lessons: [count] | Skills updated: [list or "None"] | Compacted: [files or "None"]
   ```

If you have nothing to report, still include the block with zeroes. This ensures the
behavior is habitual, not conditional.

---

## Red Flags — STOP

- A task just completed and no new user message has arrived — **STOP. Is this the session's last task? If so, treat it as session end. Load self-evaluation NOW before responding.**
- Starting implementation when SQL has pending todos from a prior session without dispatching Skeptic — **STOP. Dispatch Skeptic before the first implementation step.**
- Starting to code before reading the required skill — **STOP. Load the skill now. Do not write one line first.**
- Skipping the skill-load announcement — **STOP. State "I am using the [skill] skill to [purpose]." No skip.**
- Finishing a session without running `self-evaluation` — **STOP. Read `.github/skills/self-evaluation/SKILL.md` now.**
- Treating the "On Finish" steps as optional — **STOP. They are mandatory. Execute every step.**
- Saying "I remember the skill content" — **STOP. Memory degrades. Skills update. Load fresh every session.**
- Branch about to be created, but the plan the user approved was the pre-Skeptic version — **STOP. Re-present the post-Skeptic revised plan. Wait for explicit user approval before creating the branch.**
- About to make an irreversible change (branch creation, push) without the `execution` skill loaded — **STOP. Load `execution` before the first irreversible action.**

---

## Rationalization Prevention

| Rationalization                                    | Why it fails                                       | Correct action                              |
|----------------------------------------------------|----------------------------------------------------|---------------------------------------------|
| "This task is simple — I don't need the skill"     | Simple tasks still violate iron laws when unskilled | Load the skill. Takes 5 seconds.           |
| "I remember the skill from last session"           | Memory degrades; skills update; load fresh          | Load the skill now.                        |
| "I'll self-evaluate if anything went wrong"        | Self-evaluation finds what you didn't notice wrong | Always self-evaluate. No conditional.      |
| "Skipping announcement to save space"              | Announcement is the commitment mechanism           | State it. No skip.                         |
| "I'll skim the skill — I know the gist"            | Skimming misses updates and specific gate conditions | Read fully. The gate conditions are the point. |
| "'Always active' means I don't need to invoke honesty" | The declaration activates the rule reference, not the rule body. Without invocation, the confidence vocabulary and process language rules are absent. | Invoke `honesty` explicitly. Every session. |
| "I ran the hook script and it exited 0 — hooks are working" | Script execution ≠ CLI mechanism. The CLI reads hooks.json once at session start. An in-session fix to hooks.json is NOT active until the next session. Do not claim hooks are working until a new session confirms hook.end success=true. |
| "I'm just gathering context, not reviewing"        | Research reading to inform a plan is still review. Inline review is biased by your assumptions. | Dispatch an explore or code-review agent for any 3+ file research task. |

## Related Skills

- `self-evaluation` — the On Finish step calls this skill directly
- `honesty` — MUST be explicitly invoked at session start; hooks fail silently; full rule body is not in context until invoked
- `writing-skills` — governs skill authoring; load when creating or editing a skill
