---
name: subagent-driven-development
license: MIT
description: Use when delegating implementation tasks, confirming theories, running parallel research, or reviewing completed work.
---


## Iron Law

```
YOU MUST DISPATCH BEFORE GUESSING -- SUBAGENTS ARE CHEAP, WRONG ASSUMPTIONS ARE EXPENSIVE.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the subagent-driven-development skill to [dispatch/confirm] [brief description]."

---

## Workflow

Pick up todo -> Dispatch implementer -> Load `two-stage-review` for the status code and both review stages -> Mark done.

**Status code branches:** See the `two-stage-review` skill for all five codes and their required actions.

**After all todos:** Check plan.md for `## Feature Specification`. Present -> **Invoke Signoff (Ceremony 5 of the `three-amigos` skill: the pre-merge whole-feature review that returns ACCEPTED or REVISIONS NEEDED)** before `finishing-a-development-branch`. Absent -> dispatch final code reviewer -> `finishing-a-development-branch`.

**Do not advance past any todo until Stage 1 (spec review) returns PASS and every file the todo changed has a Stage 2 (quality review) verdict block that advances under the `two-stage-review` skill's Stage 2 rule -- both stages are run under that skill.**

See `references/SDD_LOOP.md` (Subagent-Driven Development (SDD) loop) for the full decision tree with complete ASCII flow.

---

## BEFORE PROCEEDING

Before dispatching any subagent:

1. The todo has a single, clear objective -- no compound tasks bundled together. Any specific limits, counts, or numbers in the task description are verified from source files, not from memory.
2. The agent prompt includes all necessary context: file paths, constraints, and return format.
3. A worktree exists for this agent. **All agents -- read-only and write-side alike -- run in a worktree.** Work done inline by the main agent (the "do inline" rows of the Dispatch Decision Table) is exempt -- the worktree rule attaches to dispatch.
   See `references/WORKTREE_SETUP.md` for the `{{WORKTREE_PATH}}` value and the read-only exemption; the setup commands are in the `using-git-worktrees` skill. `references/WORKTREE_SELF_CHECK.md` is the canonical self-check block that dispatched agent templates run on start.
4. If a pre-built template exists in `.claude/agents/` for this task type (index: `references/AGENT_TEMPLATES.md`): use it instead of injecting rules inline; general-purpose only under the rule in `references/MODEL_SELECTION.md`.
5. Agent type is correct for the task: explore for read-only research, `skill-reviewer.md` or `code-quality-reviewer.md` for Stage 2 review (grouped as the `two-stage-review` skill's Stage 2 rule says), `implementer.md`+worktree for file modifications, general-purpose for build/test/lint.
6. Dispatch text is shipped text: the implementer builds on it and the reviewers review the result as the implementer's own, so a label, tag, or wrong tool claim in the prompt ships as a defect. The prompt for this dispatch -- research or implementation alike -- was written to a file before sending, and the dispatch message points the agent at that file.
7. That prompt file passed the pre-PR hygiene sweep of the `finishing-a-development-branch` skill plus one more grep for spelled-out issue references (`\b[Ii]ssues?[ ]+#?[0-9]+\b`), and the sweep output (or "0 hits") is pasted in the dispatch turn.
8. Every claim in the prompt file about a tool, SDK (software development kit), library, or command-line interface (CLI) flag was verified by running the command or reading the target repo's config (package manifest, CI file), or is labeled `unverified` in the prompt. Enforcement for items 6-8 is procedural self-check with no detector; the checkable signal is the sent prompt file -- a label, tag, or unlabeled tool claim in it is the violation.
9. Every verification command written into the prompt file (a grep, wc, sed, or test the implementer must run and paste) was run by the dispatcher against one input where it must pass and one where it must fail, with both outputs pasted in the dispatch turn. A check that passes on both, or that cannot be made to fail, is redesigned before dispatch. Enforcement is procedural self-check with no detector; the checkable signal is the dispatch turn -- a verification command with no paired pass/fail run above it is the violation.

[+] All 9 met -> dispatch the agent
[-] Any unmet -> refine the todo, complete the prompt, create the worktree, select the correct agent type, or sweep, verify, and pass/fail-prove the prompt file before dispatching

**Unscoped-sweep rule for stale-reference todos:** any todo whose objective is 'fix the remaining/stale X' MUST begin with an unscoped repo-wide sweep; the implementer pastes the sweep command and its full output, and the todo's scope is the adjudicated sweep output -- never a pre-listed file set. Such dispatch prompts MUST NOT contain a 'do not touch any other file' constraint. Stage 1 treats an implementer report lacking the sweep command and its literal output as GAPS. Splitting a 'fix the remaining X' objective into per-site todos with pre-listed files is the same violation -- the sweep still comes first, and the todo set is derived from its adjudicated output.

---

## Canary

When applying this skill, before dispatching any agent, state this line in your response:

> `Worktree: [output of: git -C .worktrees/agent-<name> rev-parse --show-toplevel]`

Canary rationale: references/SDD_RATIONALE.md.

---

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
| "About to create a worktree without `using-git-worktrees` loaded" | STOP. Load `using-git-worktrees` first -- every time, without exception. The session-bootstrap On Start table maps "Parallel agent work / A/B testing" to this skill. Creating worktrees without it is a retroactive-load violation. |
| "A template exists but I'll build the prompt manually" | STOP. Use the pre-built template from `.claude/agents/`. Do not reinvent it. |
| "About to investigate a runtime behavior bug by reading source code inline" | STOP. Dispatch a researcher agent. "Build + observe" is a required method for runtime behavior bug hypotheses (symptom can only be observed by running the app -- see the `systematic-debugging` skill Phase 1). Inline code reading produces a theory, not an observation artifact. |
| "These two todos form a 'Phase N' -- I'll dispatch them together" | STOP. Phase is a planning concept, not a dispatch unit. Bundling todos as a phase bypasses the one-clear-objective gate (BEFORE PROCEEDING item 1). Split unconditionally before dispatch. |
| "Dispatching a post-merge verification agent to check files" | STOP. Provide explicit paths from the MAIN repo root (e.g. `[REPO_ROOT]/skills/...`) in the agent prompt. Without explicit paths, agents discover worktree copies and produce false REJECT verdicts on changes that are correctly merged. |
| "Reporting the number of files changed on a branch (`git diff base..HEAD --name-only \| wc -l`)" | STOP. First inspect `git log --oneline base..HEAD`. If any commits appear to predate this feature's work (PR-numbered commits, prior-session commits), identify the correct base before running the count. Presenting a count from an unverified range is a confidence-without-evidence claim. |
| "Writing a task that targets a specific line in a file" | STOP. Read the full file and grep for all instances of the pattern before writing the task scope. A task scoped to one line that misses two others creates an incomplete implementer dispatch that the Skeptic catches at extra cost. |
| "I broadened a section's intro or heading to a wider scope" | STOP. Re-read every child item under that section for narrower-scope language before committing. A widened heading over unchanged child items creates a contradiction the next reader inherits. |
| "Writing a 'fix remaining X' dispatch with a pre-listed file scope or a do-not-touch-other-files constraint" | STOP. The todo must instruct the implementer to run the unscoped sweep first and paste the command + full output in its report; scope is the adjudicated sweep output, never a pre-listed set. |
| "Launching a spend-bearing child (claude -p, a workflow run) under a prior 'go'" | STOP. Consent is per invocation -- a prior approval covers neither retries nor new launches. Write the script; the user pulls the trigger. |
| "Dispatching general-purpose without naming the template considered and passing `model`" | STOP. It inherits your model. Name the template that does not fit, state the tier reasoning, and pass `model` explicitly (`references/MODEL_SELECTION.md`). |
| "Implementer result received and `two-stage-review` is not loaded" | STOP. Load `two-stage-review` before reading the status code; the status-code table and both review stages live there. |
| "About to send a dispatch prompt containing a task tag, an issue number, or a tool/CLI claim I have not run" | STOP. Dispatch text is shipped text (BEFORE PROCEEDING items 6-8). Write the prompt to a file, run the sweep on that file and paste its output, run or read the source for every tool claim, and label what you cannot verify. |
| "Writing a verification command into a dispatch prompt that I have only seen pass" | STOP. A check that has never failed is unproven. Run it on one must-pass and one must-fail input, paste both, and redesign it if it cannot fail (BEFORE PROCEEDING item 9). |

---

## Dispatch Decision Table

**Context:** Deciding, for one step of a todo, whether to dispatch an agent or do the step inline in the coordinator's own context.
**Forces:** Inline is cheaper and faster and needs no worktree, but it inherits the coordinator's assumptions and reads files into a context that is already large. A dispatch pays a fixed prefix (the agent's skills and template) and a worktree, but returns an independent result. The table draws the line at read-only work that is small enough to fit: anything that writes a file, or reads more than a couple of files, is dispatched.

| Task | Dispatch? | Type |
|------|-----------|------|
| Exploring unfamiliar APIs or libraries | Yes | explore agent |
| Scanning 5+ files for patterns | Yes | explore agent |
| Confirming a theory or assumption | Yes | explore agent |
| Validating a plan before implementation | Yes | Skeptic + plan-reviewer pair (see writing-plans skill) |
| Code review (Stage 2) | Yes | `skill-reviewer.md` for skill `.md` files, `code-quality-reviewer.md` for code/config files -- one dispatch per group of at most two files that implement one change, one verdict block per file (the `two-stage-review` skill, Stage 2) |
| Architecture review (per-file) | Yes | `architecture-reviewer.md`, 1 per file -- the template takes one file path, so no grouping |
| Skill review | Yes | `writing-skills` + `skill-reviewer.md` agent template |
| Multi-file implementation with file isolation | Yes | `implementer.md` + git worktree |
| Investigating a runtime behavior bug (symptom can only be observed by running the app -- see the `systematic-debugging` skill Phase 1 for definition) | Yes | researcher agent ("Build + observe" is a required method for this hypothesis type) |
| Quick grep/glob in 1-2 files | No | do inline (read-only tasks only -- implementation todos require subagent dispatch regardless of estimated size) |
| Reading one known file | No | do inline |
| Single-step trivial command | No | do inline (read-only tasks only, AND if the command reads file content, the file must be under 2 000 tokens -- larger files require explore agent dispatch; implementation todos require subagent dispatch regardless of size) |

---

## Git Worktrees for Parallel Work

See the `using-git-worktrees` skill for full worktree lifecycle, commands, and safety gates.

---

## Model Selection

See `references/MODEL_SELECTION.md` for model tier table and concurrency rules.

---

## Rationale, Evidence, Delegation, Anti-Patterns

See `references/SDD_RATIONALE.md` for: why subagents are mandatory, the empirical evidence mandate, delegation quality rules, and anti-patterns.

---

## Related Skills

- `two-stage-review` -- handles every implementer result: status code, canary confirmation, Stage 1 spec review, Stage 2 quality review
- `using-git-worktrees` -- isolation for every dispatched agent
- `dispatching-parallel-agents` -- parallel dispatch patterns; one worktree per agent

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The skill says use worktrees -- I'll follow it when I remember" | The skill is not re-read before every dispatch. The worktree PATH in the prompt is the structural check -- not re-reading the skill. No path in the prompt = no dispatch. Run the 4-step worktree creation check in the `using-git-worktrees` skill first. |
| "I'll add the worktree after dispatching" | Worktrees MUST exist before dispatch. The agent needs the worktree path in its prompt -- it cannot create its own isolation after the fact. |
| "I'll include the rules in the prompt instead of using a template" | Injected rules drift between sessions. Pre-built templates in `.claude/agents/` are the single source of truth. Use them. |
| "These todos form a natural 'Phase N' -- I'll dispatch them together" | Phase is a planning label, not a dispatch unit. Compound dispatch bypasses the sizing gate -- the outlier agent cost is proportional to the bundled scope. Split unconditionally. One todo = one implementer dispatch, always. |
| "I already know what to do -- the researcher step is overhead" | YOU MUST dispatch the researcher.md template to confirm assumptions before acting. |
| "I dispatched an audit subagent -- that's a complete audit" | NO. Name every dimension the agent must check in the prompt. An unnamed dimension will not be checked. The audit prompt is the specification -- an incomplete specification produces an incomplete audit. |
| "No `## Feature Specification` in plan.md -- that means Ceremony 5 doesn't apply" | Absence signals Discovery never ran. If Discovery was required for this task (new or unclear Acceptance Criteria (AC)), surface that gap to the user before dispatching the final code reviewer. Do not silently skip Three Amigos routing. |
| "Todo is short -- I'll do it inline" | BANNED. All todos require implementer subagent dispatch regardless of estimated size. Size assessment before execution is speculation -- the outlier case always exists. |
| "The user approved the last run -- this retry is covered" | Spend-bearing launches need explicit consent PER INVOCATION. A failed launch returns to the user for a fresh go; a silent retry spends money without authorization. Ask before every launch. |
| "The dispatch prompt is scratch text -- hygiene applies to shipped files, not to what I dictate to an implementer" | The prompt IS shipped text: the implementer builds on it and the reviewers review the result as the implementer's own. Three measured defects (a dictated issue tag, a wrong SDK line, a wrong CLI flag) each cost a full dispatch round trip. Check before sending. |
| "The check is a one-line grep -- it obviously fires on the target" | Every externally caught defect in one scored coordination session was a one-line check that could not fire as claimed: a fixed-string grep on a phrase that wraps, a filter that breaks on an indented continuation, a line offset that assumed a fixed header. Each cost a full implementer or reviewer round. Run the check on a must-pass and a must-fail input before dispatch and paste both. |
