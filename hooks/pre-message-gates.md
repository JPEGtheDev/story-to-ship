<IMPORTANT>
## Bootstrap Gate -- Tool Call Required

```
READING INJECTED HOOK TEXT IS NOT LOADING A SKILL.
IF NO COMPLETED session-bootstrap Skill CALL IS VISIBLE IN CONTEXT,
YOU MUST INVOKE IT BEFORE ANY OTHER TOOL. No exceptions.
```

Check this session's visible context now for a completed `Skill` tool call with `skill: session-bootstrap`.

- If the call is absent: your FIRST tool call in this response MUST be the `Skill` tool with `skill: session-bootstrap`, sent alone -- not batched with any other tool call. Invoke it BEFORE any task-matched skill, even a skill whose trigger names words in the user's prompt. Load task skills only AFTER `session-bootstrap` returns.
- If this session opened with "This session is being continued from a previous conversation that ran out of context": the call is absent. A compaction summary claiming skills were loaded is pseudo-memory, not a completed tool call.
- If the completed call itself is visible in context: proceed to "BEFORE SENDING ANY RESPONSE" below.

NONE of the following count as loading `session-bootstrap`:

1. Reading this hook text or the session-start hook text -- injected text is a pointer to the skill, not the skill
2. Writing "I am using the session-bootstrap skill" in a response -- an announcement without a matching `Skill` tool call in the SAME response is a false statement
3. Invoking a different skill that matched the task -- task skills do not substitute
4. Remembering skill content from a summary or a prior session

---

## Skill Reload Triggers -- Invoke the Skill Tool When:

1. Picking up a new todo: invoke the skill(s) for that todo's domain first
2. 3 user prompts have passed with no `Skill` tool call: invoke the skill(s) for the current work now
3. The user corrects or redirects you: invoke the misapplied skill immediately
4. Context was compacted: invoke every skill the current task requires

"Reload" means a `Skill` tool call in this session -- nothing else qualifies. Do NOT say "I remember the skill content." The skill routing table is inside `session-bootstrap`.

---

## BEFORE SENDING ANY RESPONSE

1. No banned vocabulary ("should work", "that should do it") is present in the draft -- this applies to ALL output: chat responses, PR comment replies, commit messages, and any text sent via CLI tools
2. Any completion claim ("done", "fixed", "works") has inline verification output attached
3. Any confidence expression has empirical evidence cited inline
4. No forbidden hedge phrases from the honesty skill's Talk Straight table are present
5. No non-ASCII characters are present in the draft; use ASCII-only text

[+] All met -> send the response
[-] Any unmet -> rewrite the offending phrase or run the required verification before sending
</IMPORTANT>
