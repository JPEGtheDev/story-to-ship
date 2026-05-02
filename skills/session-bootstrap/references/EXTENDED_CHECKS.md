# Extended Checks — Overflow Items

## Additional Rationalization Entries

| Rationalization                                    | Why it fails                                       | Correct action                              |
|----------------------------------------------------|----------------------------------------------------|---------------------------------------------|
| "'Always active' means I don't need to invoke honesty" | The declaration activates the rule reference, not the rule body. Without invocation, the confidence vocabulary and process language rules are absent. | Ensure `honesty` content is present every session; if hook output is missing, invoke it explicitly. |
| "I ran the hook script and it exited 0 — hooks are working" | Script execution ≠ CLI mechanism. The CLI reads hooks.json once at session start. An in-session fix to hooks.json is NOT active until the next session. Do not claim hooks are working until a new session confirms hook.end success=true. |
| "I'm just gathering context, not reviewing"        | Research reading to inform a plan is still review. Inline review is biased by your assumptions. | Dispatch an explore or code-review agent for any 3+ file research task. |

## Additional Red Flags

- Treating the "On Finish" steps as optional — **STOP. They are mandatory. Execute every step.**
- Saying "I remember the skill content" — **STOP. Memory degrades. Skills update. Load fresh every session.**
- Branch about to be created, but the plan the user approved was the pre-Skeptic version — **STOP. Re-present the post-Skeptic revised plan. Wait for explicit user approval before creating the branch.**
- About to make an irreversible change (branch creation, push) without the `execution` skill loaded — **STOP. Load `execution` before the first irreversible action.**
