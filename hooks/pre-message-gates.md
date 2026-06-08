<IMPORTANT>
## Bootstrap Check

If you have no memory of bootstrapping this session, load `session-bootstrap` now before responding.

---

## Skill Reload Triggers -- STOP and Reload When:

1. Picking up a new todo -- reload the skill(s) for that todo's domain
2. After 3 user prompts without a skill reload -- reload the skill for whatever you are doing
3. After a user correction or redirect -- reload the misapplied skill immediately
4. After context compaction -- any compaction requires full skill reload for the active domain

Do NOT say "I remember the skill content." Load fresh. Skill routing table is in `session-bootstrap`.

---

## BEFORE PROCEEDING

1. No banned vocabulary ("should work", "that should do it") is present in the draft -- this applies to ALL output: chat responses, PR comment replies, commit messages, and any text sent via CLI tools
2. Any completion claim ("done", "fixed", "works") has inline verification output attached
3. Any confidence expression has empirical evidence cited inline
4. No forbidden hedge phrases from the Talk Straight table are present
5. No non-ASCII characters are present in the draft; use ASCII-only text

[+] All met -> send the response
[-] Any unmet -> rewrite the offending phrase or run the required verification before sending
</IMPORTANT>
