---
name: session-bootstrap
license: MIT
description: Use when opening a new conversation to load required skills, identify task type, and restore session context before acting.
---


## Iron Law

```
READ THE SKILL. THEN ACT. NEVER ACT THEN READ.
YOU MUST read all required skills before writing any code or sending any plan. No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

Skills contain rules that change what you do. Reading a skill AFTER acting defeats the purpose.

**Announce at start:** "I am using the session-bootstrap skill to load required skills for this session."

---

## Skill Refresh -- Mandatory

**Stale skill context is worse than no skill.** Skills evolve. Context windows truncate. Skills loaded early in a session may no longer be active when you need them.

### When to Reload a Skill

Reload the relevant skill(s) immediately when ANY of these occur:

1. **Picking up a new todo** -- reload the skill(s) for that todo's domain before starting work
2. **After 3 user prompts** without a skill reload -- reload the skill for whatever you are currently doing
3. **After a user correction or redirect** -- the correction is evidence the skill was misapplied or is stale; reload it
4. **After context compaction** -- any compaction event requires full skill reload for all skills required by the current task

**Announce the reload:** "Reloading `[skill-name]` -- [reason: new todo / 3 prompts / correction]."

Do NOT say "I remember the skill content." A remembered skill is an unverified skill. Load fresh.

### `honesty` -- Co-Equal Peer Skill

`honesty` is NOT managed by `session-bootstrap`. It is a co-equal peer skill with its own hook injection. The pre-message hook injects the Honesty Gate into every turn automatically. The session-start hook injects the full Honesty Gate at session start.

If neither hook output is visible in context, load `honesty` explicitly before responding. Do NOT proceed with a task-specific skill while honesty content is absent from working context.

---

## On Start -- Minimum Skill Loads by Task Type

Before writing code, read the skill(s) relevant to your task. If the task touches multiple domains, read multiple skills in parallel (they are independent reads). `honesty` is injected by hook -- load it explicitly only if hook output is absent.

| If the task involves...                        | MUST read these skills BEFORE acting               |
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
| Executing any plan that has pending todos (picking up plan.md or a todo list) | `subagent-driven-development` -- load BEFORE dispatching the first implementer, not after |
| Parallel agent work / A/B testing            | `subagent-driven-development`, `using-git-worktrees` |
| Creating user stories                        | `user-story-generator`, `user-story-estimation`    |
| Creating or editing a skill file             | `writing-skills`                                   |
| Resuming from a prior session with pending tasks | `writing-plans`; if `## Feature Specification` present in plan.md: dispatch `three-amigos` Refinement; otherwise dispatch the Skeptic Agent (see `writing-plans`), before first implementation step |
| Schema design, new data structure, or plan with >=5 implementation items | `brainstorming`, `writing-plans` |
| Auditing communication quality or postmortem | `honesty`, `session-postmortem`                    |
| Any new plan with 2+ todos or an architectural decision | `writing-plans`; if `## Feature Specification` present in plan.md: dispatch `three-amigos` Refinement; otherwise dispatch the Skeptic Agent, before first implementation step |
| Auditing or reorganizing a collection of files, tasks, or artifacts with multiple valid structural approaches | `brainstorming`, `writing-plans` |
| Starting a new project from scratch | `greenfield-discovery` |
| Task references a GitHub issue number (#NNN), OR task description contains "acceptance criteria", "AC:", or Given/When/Then blocks -- if unsure whether ACs exist, read the issue before planning | `three-amigos` -- run Discovery (Ceremony 1) before planning begins; surfaces AC ambiguities as `[UNCLEAR:]` labels before the plan is built |
| Summarizing external resources (articles, web pages, files) for knowledge extraction | `summarization` |

If unsure, read `code-quality` -- it applies to every code task.

**Loading protocol:**
1. Invoke `honesty` first -- every session, regardless of task type
2. Identify task type(s) from the table above
3. Load all required skills before writing a single line of code or sending a plan
4. Announce each skill load: "I am using the [skill-name] skill to [purpose]."

## BEFORE PROCEEDING

1. `honesty` invoked first -- before any other skill
2. Task type(s) identified from the On Start table above
3. All required skills for this task type loaded (in parallel if multiple domains)
4. Skill load announcement made for each loaded skill
5. `git status` checked in main working tree -- if uncommitted changes exist with no active work in progress, identify their source (prior agent? manual edit?), read the diff, then commit or revert explicitly before starting new work. Ghost commits from prior agents are a recurring risk.
6. If resuming a prior session: pending tasks checked (via TaskList); Skeptic Agent dispatched before first implementation step
7. If resuming a session that was interrupted mid-task: confirmed the prior session's self-evaluation ran (look for `### Session Self-Evaluation` block in session memory), OR loading `self-evaluation` now before picking up the first new todo
8. Stored memories checked for user-specified model preference overrides -- applies to all agent dispatch decisions this session
9. If this task requires reading 3+ files for research or review: an explore or code-review agent is dispatched -- NOT done inline
10. Session hooks checked: if sessionStart or userPromptSubmitted hook failed, all skills MUST be invoked manually this session -- no auto-loading is available
11. If a hook config fix was committed during this session: that fix is NOT active until the NEXT session. Do NOT claim hooks are working. The CLI reads hooks.json once at session start -- in-session commits to hook files do not take effect until the session is restarted.
12. If `docs/INDEX.md` exists: load it now. Load any applicable `docs/<domain>/INDEX.md` files. These indexes map the repo's documented scope and goals -- load them before planning or implementing anything this session.

[+] All met -> proceed with session work
[-] Any unmet -> complete the unmet step now before writing code or sending a plan

---

## On Finish -- Self-Evaluate and Compact

**Self-evaluation fires at session END.** If a major task completes mid-session with no further work planned, treat it as session end and execute On Finish now.

**Before your final message to the user**, execute all of the following:

1. **Load** the `self-evaluation` skill and follow its steps.
2. **Identify lessons learned** -- mistakes made, user corrections, patterns discovered.
3. **Check existing skills** -- is the lesson already documented? If yes, skip.
4. **Apply updates** -- for High/Medium priority lessons, update the relevant skill file
   and bump its version in the YAML frontmatter. Commit the skill update with the
   session's work.
5. **Compact** -- scan any files you touched for bloated comments or duplicated docs.
   Migrate detail to skills/docs and leave 1-line references.
6. **Report** -- include a `### Session Self-Evaluation` block in your final message:
   ```
   ### Session Self-Evaluation
   Lessons: [count] | Skills updated: [list or "None"] | Compacted: [files or "None"]
   ```

If you have nothing to report, still include the block with zeroes. This ensures the
behavior is habitual, not conditional.

---

## Red Flags -- STOP

- A task just completed and no new user message has arrived -- **STOP. Is this the session's last task? If so, treat it as session end. Load self-evaluation NOW before responding.**
- Starting implementation when prior session tasks are pending without dispatching the Skeptic Agent -- **STOP. Dispatch the Skeptic Agent before the first implementation step.**
- Picking up plan todos without `subagent-driven-development` loaded -- **STOP. Load `subagent-driven-development` before dispatching the first implementer. The skill contains the review protocol that every todo requires.**
- Starting to code before reading the required skill -- **STOP. Load the skill now. Do not write one line first.**
- Skipping the skill-load announcement -- **STOP. State "I am using the [skill] skill to [purpose]." No skip.**
- Announced "I am using skill X" without invoking the skill tool in the same response -- **STOP. An announcement without a matching `skill.invoked` event is a false statement. The announcement and the `skill` tool call MUST occur in the same turn. Load the skill now.**
- Finishing a session without running `self-evaluation` -- **STOP. Load the `self-evaluation` skill now.**
- Resuming from a prior session that was interrupted mid-task (no `### Session Self-Evaluation` block in session memory) and about to pick up a new todo -- **STOP. The prior session's self-evaluation did not complete. Load `self-evaluation` for the prior session's work before starting any new todos.**
- Treating the "On Finish" steps as optional -- **STOP. They are mandatory. Execute every step.**
- Saying "I remember the skill content" -- **STOP. Memory degrades. Skills update. Load fresh every session.**
- Branch about to be created, but the plan the user approved was the pre-Skeptic version -- **STOP. Re-present the post-Skeptic revised plan. Wait for explicit user approval before creating the branch.**
- About to make an irreversible change (branch creation, push) without the `execution` skill loaded -- **STOP. Load `execution` before the first irreversible action.**
- User says "check out a working branch" or "work on a branch" without naming a specific branch -- **STOP. The default is always `git checkout main && git pull && git checkout -b <new-branch>`. Using an existing named branch requires the user to name it explicitly. "Working branch" without a specific name means new branch from main.**

---

## Rationalization Prevention

| Rationalization                                    | Why it fails                                       | Correct action                              |
|----------------------------------------------------|----------------------------------------------------|---------------------------------------------|
| "This task is simple -- I don't need the skill"     | Simple tasks still violate iron laws when unskilled | Load the skill. Takes 5 seconds.           |
| "I remember the skill from last session"           | Memory degrades; skills update; load fresh          | Load the skill now.                        |
| "I'll self-evaluate if anything went wrong"        | Self-evaluation finds what you didn't notice wrong | Always self-evaluate. No conditional.      |
| "Skipping announcement to save space"              | Announcement is the commitment mechanism           | State it. No skip.                         |
| "I'll skim the skill -- I know the gist"            | Skimming misses updates and specific gate conditions | Read fully. The gate conditions are the point. |
| "'Always active' means I don't need to invoke honesty" | The declaration activates the rule reference, not the rule body. Without invocation, the confidence vocabulary and process language rules are absent. | Invoke `honesty` explicitly. Every session. |
| "I ran the hook script and it exited 0 -- hooks are working" | Script execution != CLI mechanism. The CLI reads hooks.json once at session start. An in-session fix to hooks.json is NOT active until the next session. Do not claim hooks are working until a new session confirms hook.end success=true. | Restart the session. Verify hook.end success=true fires before claiming hooks are active. |
| "I'm just gathering context, not reviewing"        | Research reading to inform a plan is still review. Inline review is biased by your assumptions. | Dispatch an explore or code-review agent for any 3+ file research task. |
| "An existing branch with a relevant name is the correct base for this work" | Branch name is not branch currency. The correct base is main unless the user names a specific branch. An existing feature branch that predates a recent merged PR silently contaminates all downstream agents with stale state. | Run `git checkout main && git pull && git checkout -b <new-branch>`. |

## Related Skills

- `self-evaluation` -- the On Finish step calls this skill directly
- `honesty` -- MUST be explicitly invoked at session start; hooks fail silently; full rule body is not in context until invoked
- `writing-skills` -- governs skill authoring; load when creating or editing a skill
