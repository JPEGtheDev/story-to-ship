<IMPORTANT>
## Bootstrap Gate

```
READING INJECTED HOOK TEXT IS NOT LOADING A SKILL.
NO EXCEPTIONS.
```

No completed `Skill` call with `skill: session-bootstrap` visible in context: your FIRST tool call this response MUST be `Skill(session-bootstrap)`, sent alone -- not batched. Otherwise proceed below.

A "continued from a previous conversation" preamble means the call is absent; a compaction summary is not a completed call.

## Skill Reload Triggers

Only a fresh `Skill` tool call counts -- not a Read call, memory, or hook text. Reload when:

1. New todo -- invoke that todo's domain skill(s) first
2. 3 user prompts with no `Skill` call -- reload the skill(s) for current work
3. User correction or redirect -- reload the misapplied skill
4. Context compacted OR session resumed (`--continue`/`--resume`) -- reload every skill + `honesty`; a 'resume directly' summary does NOT waive it (completed-call evidence does not survive)

For full reload rules and examples, see the skill.

---

## Core Skill Routing (per turn)

Invoke `honesty` immediately after `session-bootstrap` returns, before any task skill.

Process combos: before any completion claim, commit, or PR, load `verification-before-completion`. For any plan with 2+ todos, dispatch the Skeptic + plan-reviewer pair; if plan.md contains a `## Feature Specification`, dispatch `three-amigos` Refinement instead. For multi-step planning, load `writing-plans` first. Before dispatching any subagent, load `subagent-driven-development` and `using-git-worktrees` together.

Domain skills keep their own dispatch rows -- not here.
</IMPORTANT>
