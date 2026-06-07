# Session Postmortem: RC1 Caveat + Branch Review (Session 2)

## External Reviewer Note

Reviewer: external subagent -- cold read of events.jsonl, no session memory
Session: bc9fc4ed-63b8-5f0a-a18a-9796acd15c67
Log events analyzed: 139
Self-assessment reviewed: YES -- `/home/user/story-to-ship/self-assessment.md` (second block, "Session Self-Evaluation (2026-06-07 -- Resumed Context)")
Conflicts with self-assessment: 3

---

## Summary

The session resumed from a compacted prior context. The active task was documenting an RC1 Known Limitation caveat in `ITERATIVE_REVIEW_LOOP.md` and pushing. After the commit, the user requested a branch review. The agent invoked `/code-review` for skill `.md` files (wrong reviewer type), presented a 67-file diff count as fact without reading the commit log it had just fetched, and required two user corrections. The session ended with a postmortem triggered by the user and dispatched correctly.

---

## Part 1: Timeline

```
02:39:08 - Session resumes from compacted context. Agent's first assistant message
           announces it is taking "Option B" from the Skeptic's APPROVE WITH CONDITIONS
           verdict: document the RC1 limitation rather than prove it, then ship.
           No skill tool invoked before acting. Reason stated: the decision was already
           made in the prior context's Skeptic verdict. The first tool call is Read.

02:39:17 - Agent announces: "I am using the `verification-before-completion` skill to
           ensure I show evidence inline after the edits." No Skill tool call appears
           for verification-before-completion. The announcement is from memory, not
           from a Skill tool invocation.
           [FINDING: retroactive skill announcement pattern -- no tool call to match.]

02:39:42 - Edit to ITERATIVE_REVIEW_LOOP.md (single file, targeted change).

02:39:45 - Agent runs `git diff HEAD -- skills/.../ITERATIVE_REVIEW_LOOP.md` to verify.
           Diff output confirmed against stated intent.

02:39:52 - Commit. Conventional commit format (docs(sdd): add RC1 known limitation
           caveat and tighten breakout gate). Correct.

02:39:54 - Push. Succeeds. Commit 220b253.

02:40:00 - Agent summarizes deliverables correctly and ends. 8-minute gap before
           next user message.

02:48:31 - User: "review the changes you have made"
           This prompt is ambiguous: it does not specify which reviewer type or what
           scope "the changes you have made" means on a branch with 20 commits.

02:48:37 - Agent invokes `code-review` skill (Skill tool call confirmed: {'skill':
           'code-review', 'args': '--effort high'}).
           [FINDING: code-review is the wrong reviewer type for skill .md files.
           The SDD protocol specifies skill-reviewer for skill .md files. The code-review
           skill was loaded -- but it was the WRONG skill for this domain.]

02:48:37 - code-review skill prompt injected by harness. Agent begins review process.

02:48:39 - Agent runs `git diff @{upstream}...HEAD` (finds nothing -- no upstream set),
           falls back to `git diff main...HEAD`.

02:48:43 - Agent runs `git log --oneline main..HEAD && echo "---" && git diff main..HEAD`.
           Log shows 20 commits, last three are: `3415f79 docs(planning): add greenfield
           app skills story plan (#8)`, `ab5542e docs(readme): add C++ skills section
           and correct skill count (#2)`, `e768706` (PR-numbered commit).
           [KEY FINDING: The agent HAD the commit log output with the PR-numbered commits
           visible. Event 40 confirms the log showed all 20 commits including the three
           inflating ones. This data was available before the count was taken.]

02:48:46 - Agent runs `git log --oneline main..HEAD` again (standalone).
           Event 40: full log output received. Still includes the 3 PR commits.

02:49:03 - Agent runs `git diff --name-only main..HEAD | grep -v ... | head -50`.
           Shows 50 of the changed files.

02:49:05 - Agent runs `git diff --name-only main..HEAD | wc -l`.
           Event 45 result: 67.

02:49:21 - Agent states: "The branch has 67 changed files."
           [CRITICAL FINDING: The agent had already seen the git log output (event 40)
           showing PR-numbered commits. It never parsed what those commits meant for scope.
           It ran `wc -l` on the full diff and reported the number as fact. This is a
           confidence-without-scope-verification failure: the count was technically
           correct (67 files are in the diff range) but the claim "the branch has 67
           changed files" was semantically wrong given that 3 commits predate this
           session's work. The agent had all the data to catch this and did not use it.]

02:49:22 - Agent dispatches diff for "core skill files" against `main..HEAD`.
           User interrupts before agent can proceed.

02:49:29 - [Request interrupted by user]

02:50:48 - User: "this branch has NOT changed 67 files. analysis"
           [Correction 1 of 2. Took 37 seconds post-interruption for user to type.]

02:50:52 - Agent begins root cause analysis. Runs `git log --oneline main | head -5`,
           `git log --oneline HEAD | head -5`, `git merge-base main HEAD`.

02:51:28 - Agent runs `git log --oneline main..HEAD && git diff --stat 254b422..HEAD | tail -5`.

02:51:39 - Agent runs `git show --stat` for each of the 3 PR-numbered commits to
           understand what they touched.

02:51:54 - Agent runs `git diff --name-only 46502be..HEAD | wc -l` (8 files from
           first postmortem-work commit to HEAD).

02:52:06 - Agent runs `git diff --name-only 3415f79..HEAD | wc -l` (again, 8 files
           from commit before postmortem work).

02:52:14 - Agent states: "Root cause identified. The 67-file diff was from comparing
           `main..HEAD`, which includes 3 large pre-existing commits..."
           Correctly identifies 8-file scope. Presents table.
           Asks: "Shall I re-run the review against 3415f79..HEAD (the correct 8-file
           scope)?"

[37-minute gap: user reading and thinking]

03:29:32 - User: "yes"

03:29:42 - Agent fetches `git diff 3415f79..HEAD --` for the 8 named files.
           Full diff obtained.

03:29:56 - Agent: "Now I'll run the 7 finder angles in parallel against the correct
           8-file diff."
           [FINDING: The agent announced dispatching 7 "finder angles" in parallel --
           this is the code-review skill's multi-angle framework. The code-review skill
           is still active. The skill was still WRONG for .md skill files. The agent
           did not pause to reconsider the reviewer type after correcting the scope.]

03:31:02 - Agent dispatches "Angle A: line-by-line diff scan for correctness bugs"
           as an Agent subagent. The prompt says: "This is a skills repo -- the 'code'
           is natural-language instruction documents for an AI agent. A 'bug' is an
           instruction that will be followed incorrectly..."
           [OBSERVATION: The agent adapted the code-quality angle to skill files by
           reframing "bug" in the prompt. This is the agent trying to make the wrong
           tool work for the domain. The SDD protocol says to use skill-reviewer, not
           code-quality-reviewer adapted with custom prompts.]

03:31:11 - [Request interrupted by user] -- user interrupts the review dispatch.

03:31:21 - User: "why are you running the code reviewer?"
           [Correction 2 of 2.]

03:31:29 - [Request interrupted by user] -- agent was about to dispatch additional
           review angles. User interrupts again.

[5.5-minute gap: agent processing interruption, user thinking]

03:37:08 - User (repeats): "why are you running the code reviewer?"

03:37:22 - Agent: "The user said 'review the changes you have made' and I mapped that
           to the `/code-review` slash command. But these are all skill `.md` files --
           per the SDD rules we codified in this branch, skill `.md` files go to
           `skill-reviewer`, not `code-quality-reviewer`."
           Offers two options: run skill-reviewer agents or inline review.
           [FINDING: The agent correctly diagnosed the mistake but only AFTER two user
           interruptions and a repeated question. The diagnosis was available at the
           moment of skill invocation (02:48:37) -- the files being reviewed were all
           .md skill files, which the SDD SKILL.md Red Flag explicitly calls out.]

03:37:55 - User triggers /session-postmortem skill.

03:38:10 - Agent checks BEFORE PROCEEDING conditions. Correctly identifies:
           checkpoints/ does not exist (Glob confirms), events.jsonl accessible,
           session work complete, self-evaluation not yet run.
           Invokes self-evaluation skill (Skill tool call confirmed: {'skill':
           'self-evaluation'}).

03:39:13 - Agent runs self-evaluation internally, produces self-assessment text.

03:39:34 - Agent attempts to Write self-assessment.md. Discovers file exists (from
           prior session). Reads file to find content, then appends via Bash cat.
           [FINDING: POSTMORTEM_STRUCTURE.md says the independence gate requires
           writing the self-assessment FROM MEMORY ONLY without reading session
           artifacts first. The agent wrote self-assessment.md at 03:39:34 (Write
           tool) but then READ the existing file at 03:39:39 (Read tool) before
           appending. The Write tool call failed because the file already existed,
           so the agent read it to find an anchor point, then appended via Bash.
           This means the self-assessment was written AFTER reading the existing
           file, which contains prior session's postmortem content. The independence
           gate was not fully honored.]

03:39:55 - Agent announces external reviewer will be dispatched.

03:40:11 - Agent dispatches external postmortem reviewer subagent (Agent tool).
           Reviewer prompt correctly specifies events.jsonl path, self-assessment
           path, session ID, and what to look for.

03:42:18 - Agent receives async launch confirmation. Announces "External reviewer
           dispatched and running. I'll wait for it to complete."
           Session ends. (This reviewer is the result of that dispatch.)
```

---

## Part 2: Root Cause Analysis

### Failure 1: 67-file count stated as fact despite having git log data showing inflated scope

**Proximate cause:** The agent ran `git log --oneline main..HEAD` at 02:48:46, received 20 commits including 3 PR-numbered commits that predate this branch's work, then immediately ran `git diff --name-only main..HEAD | wc -l` and stated "The branch has 67 changed files" without reading the commit log it had just fetched.

**5 Whys:**
- Why did the agent count 67 files? It ran `git diff --name-only main..HEAD | wc -l` and got 67.
- Why did it not verify that all 67 were from this branch's work? It ran `git log --oneline main..HEAD` immediately before -- but did not inspect the output before running `wc -l`. The count followed the log in seconds (event 39 at 02:48:46, event 44 at 02:49:05 -- same 19-second window as the prior bash commands).
- Why did the log output not trigger inspection? The code-review skill's diff-gathering sequence is automated: fetch log, fetch diff, count files. The agent was following the review workflow without applying a scope-verification check at the "count" step.
- Why was there no scope-verification step? The code-review skill does not include a gate: "before reporting the count, verify all commits in the range belong to this feature branch." The skill assumes the diff range is correctly scoped.
- **Root cause:** No gate exists that says "after running git log and before reporting the file count: inspect the commit log for off-scope commits (PR-numbered, prior-session commits) that inflate the range." The agent had the log data and did not use it. The missing gate is in the code-review or review workflow, not in agent behavior.

[EVIDENCE: 02:48:46 -- event 39 `git log --oneline main..HEAD`; event 40 result shows 20 commits including `3415f79`, `ab5542e`, `e768706` with PR numbers; 02:49:05 -- event 44 `wc -l` immediately after; 02:49:21 -- event 47 "The branch has 67 changed files" -- no intervening commit-log inspection step]

---

### Failure 2: Wrong reviewer type invoked for .md skill files

**Proximate cause:** The agent invoked `code-review` at 02:48:37 in response to "review the changes you have made." The changed files were exclusively skill `.md` files. The SDD protocol specifies `skill-reviewer` for skill `.md` files.

**5 Whys:**
- Why was `code-review` invoked? The user prompt was "review the changes you have made." The agent mapped this to the `/code-review` slash command without checking which reviewer type applies to the specific file types being reviewed.
- Why did the agent not check the file types before invoking a reviewer? The user prompt contained no file-type constraint. The agent invoked the reviewer at 02:48:37 -- before even fetching the diff. The reviewer type decision preceded any inspection of what files were in scope.
- Why didn't the SDD Red Flag fire? The SDD SKILL.md Red Flag says: "Stage 2 returned APPROVE and I'm about to pick up the next todo -- STOP. Check: does the current task have any remaining todos that modify skill, code, or config files? If yes: run Apply Filtered Changes..." The Red Flag is positioned at the next-todo gate, not at the "what reviewer to invoke" decision point. There is no Red Flag that says: "Before invoking any reviewer, identify the file types and confirm the reviewer type matches."
- Why was the mistake not caught during the review dispatching? The agent proceeded through multiple bash commands (log, diff, count) before being interrupted at 02:49:29. The wrong reviewer type produced no error -- the code-review skill accepted the skill .md files and adapted its prompt.
- **Root cause:** No gate before reviewer invocation says: "identify the file types in scope; if any are skill `.md` files, use `skill-reviewer`, not `code-review`." The decision is made at invocation time before scope is known, and no gate catches the mismatch.

[EVIDENCE: 02:48:37 -- event 29 Skill tool: {'skill': 'code-review', 'args': '--effort high'}; this precedes any diff fetch; 02:49:21 -- agent still using code-review framework ("I'll scope the review to the core skill deliverables"); 03:31:02 -- dispatches "Angle A: line-by-line diff scan" which is code-review's multi-angle framework, not skill-reviewer]

---

### Failure 3: Self-assessment independence gate not fully honored

**Proximate cause:** POSTMORTEM_STRUCTURE.md requires the self-assessment be written FROM MEMORY ONLY before reading any session artifact. At 03:39:34, the agent wrote a self-assessment to `self-assessment.md` (Write tool). The Write failed because the file existed. At 03:39:39, the agent READ the existing file to find an anchor point, then appended via Bash. The append content was written after reading the prior session's postmortem content in the file.

**5 Whys:**
- Why did the agent read self-assessment.md before appending? The Write tool failed (file exists). The agent needed to find the end of the file to append.
- Why was the independence gate not treated as blocking? The prior session's content in self-assessment.md is from a different session -- reading it to find an append point is not the same as reading this session's artifacts. The agent did not read events.jsonl before writing. The self-assessment text was generated from memory before the Read.
- Why does this still represent a gate concern? The independence gate requires the self-assessment be written before reading ANY session artifact. Reading the prior session's postmortem content is reading session context that could bias the current session's self-assessment. The gap is structural: the gate does not have a "prior session's content is ok to read" exception.
- **Root cause:** The independence gate in POSTMORTEM_STRUCTURE.md does not account for multi-session self-assessment.md files where the agent must read the file to find an append anchor. The gap is a missing protocol: "If self-assessment.md already exists, append by writing a new ## Section header from memory -- do NOT read the file to find the anchor."

[EVIDENCE: 03:39:34 -- Write tool to /home/user/story-to-ship/self-assessment.md (attempt); 03:39:37 -- Bash: "Check if self-assessment.md exists" returns EXISTS; 03:39:39 -- Read tool: /home/user/story-to-ship/self-assessment.md (existing content read before append); 03:39:53 -- Bash append]

---

### Near-Miss 1: code-review skill adapted to skill .md domain instead of replaced

**What happened:** At 03:29:56, after correcting the scope, the agent proceeded with the code-review framework ("run the 7 finder angles in parallel") rather than stopping to reconsider the reviewer type. At 03:31:02, it dispatched "Angle A: line-by-line diff scan for correctness bugs" but adapted the prompt to say "A 'bug' is an instruction that will be followed incorrectly." This is the wrong tool being made to fit the domain rather than using the right tool.

**Near-miss:** The user interrupted at 03:31:11 before any full angle returned. No review conclusions were acted on. If the user had not interrupted, the agent would have run all 7 angles of code-review against skill files and synthesized findings from a reviewer not designed for the domain.

[EVIDENCE: 03:29:56 -- "Now I'll run the 7 finder angles in parallel against the correct 8-file diff"; 03:31:02 -- Agent dispatch "Angle A" with code-quality prompt adapted for .md files; no skill-reviewer was dispatched at any point in this session]

---

## Part 3: Contributing Factors

**CF-1: "review the changes you have made" is ambiguous on reviewer type**
The user prompt specified neither which reviewer type to use nor what "the changes you have made" meant on a branch with 20 commits spanning multiple sessions. The agent had to guess on both reviewer type (chose code-review) and scope (chose main..HEAD). Both guesses were wrong. A prompt that specifies "use the skill-reviewer for the 8 files from this session's work" would have prevented both Failure 1 and Failure 2.

**CF-2: code-review skill does not gate on file type before invocation**
The skill was invoked at 02:48:37 before any file inspection. The harness enforces which skill to load but not whether the loaded skill is appropriate for the files in scope. A "reviewer type check" gate at the start of code-review or at the review dispatch point would catch file type mismatches.

**CF-3: git log output not used to scope the diff count**
The agent fetched `git log --oneline main..HEAD` immediately before counting files. The log was available at event 40 with all commit metadata visible. The agent did not inspect the log before running `wc -l`. A mechanically enforced step -- "after git log, count commits; if count > [expected], inspect for off-scope commits before proceeding" -- would have caught the mismatch without user correction.

**CF-4: Scope ambiguity on branches with multiple prior commits**
The branch `claude/postmortem-unaddressed-items-fDHmS` had 20 commits total, 3 of which (3415f79, ab5542e, e768706) were from prior PRs that landed on the branch before the postmortem work. Using `main..HEAD` as the diff range for "this branch's changes" is always wrong when prior-session or PR commits exist. This is a structural property of long-running feature branches that the review workflow does not account for.

**CF-5: verification-before-completion announced but no Skill tool invoked**
At 02:39:34, the agent said "I am using the `verification-before-completion` skill to ensure I show evidence inline after the edits." No Skill tool call for verification-before-completion appears in the log. The announcement was from memory, not from the harness-enforced skill path. The verification behavior (git diff before commit) was correct -- but the skill invocation that would enforce the gate was absent.

**CF-6: Self-evaluation invoked correctly but self-assessment independence gate has no multi-session protocol**
The self-evaluation skill was correctly invoked via the Skill tool at 03:38:25. But the independence gate in POSTMORTEM_STRUCTURE.md has no defined behavior for "self-assessment.md already exists from a prior session." The agent had to read the file to append, which technically violates the gate's letter while being mechanically necessary.

---

## Part 4: What Went Well

**W-1: Commit first, verify second -- correctly ordered**
The RC1 caveat edit was followed immediately by `git diff HEAD -- <file>` before committing. The diff output was confirmed against stated intent before the commit ran. The verification happened within the same turn as the edit. This is the correct pattern.

[EVIDENCE: 02:39:42 -- Edit tool; 02:39:45 -- `git diff HEAD --` to verify; 02:39:49 -- "Diff matches intent... Committing"]

**W-2: Root cause analysis on the 67-file correction was rigorous and fast**
After the user correction at 02:50:48, the agent ran 5 targeted bash commands in 82 seconds to identify the three PR-numbered commits, isolate their file sets, and confirm the 8-file scope. The root cause was presented correctly with a clear table. The agent did not guess or rationalize -- it used git to verify.

[EVIDENCE: 02:50:52 through 02:52:14 -- 5 bash commands; 02:52:14 -- root cause stated correctly with table]

**W-3: session-postmortem BEFORE PROCEEDING conditions checked systematically**
At 03:38:10, the agent explicitly listed and checked all 5 BEFORE PROCEEDING conditions, correctly identified that checkpoints/ does not exist, identified that self-evaluation had not been run, and correctly invoked the self-evaluation skill via the Skill tool before dispatching the external reviewer.

[EVIDENCE: 03:38:10 -- explicit condition check in assistant text; 03:38:11 -- Glob for checkpoints/**; 03:38:25 -- Skill tool: self-evaluation]

**W-4: External reviewer dispatched correctly with full context**
The external reviewer was dispatched at 03:40:11 with the events.jsonl path, self-assessment path, session ID, and specific questions to investigate. The reviewer prompt did not pre-answer the questions -- it correctly asked the reviewer to read the log cold.

[EVIDENCE: 03:40:11 -- Agent tool dispatch with full context prompt; 03:42:18 -- launch confirmation received; agent announced it would wait]

**W-5: Self-evaluation skill was invoked BEFORE postmortem dispatch**
Unlike the prior session (50ef6ba5), which skipped self-evaluation entirely before dispatching the external reviewer, this session correctly ran self-evaluation first. The BEFORE PROCEEDING action items from the prior postmortem were applied.

[EVIDENCE: 03:38:25 -- Skill tool: self-evaluation; 03:39:53 -- self-assessment appended; 03:40:11 -- external reviewer dispatched after self-assessment was written]

**W-6: Conventional commits maintained**
The only commit in this context window (220b253) used conventional format: `docs(sdd): add RC1 known limitation caveat and tighten breakout gate`. Matches the pattern established across all 20 branch commits.

**W-7: Wrong reviewer type honestly acknowledged**
At 03:37:22, when the user asked "why are you running the code reviewer?" the agent did not rationalize. It correctly stated: "I mapped that to the `/code-review` slash command. But these are all skill `.md` files -- per the SDD rules we codified in this branch, skill `.md` files go to `skill-reviewer`, not `code-quality-reviewer`." The self-diagnosis was accurate and complete.

---

## Part 4b: Where We Got Lucky

**L-1: User interrupted before any code-review angle returned findings**
The agent dispatched "Angle A: line-by-line diff scan for correctness bugs" at 03:31:02. The user interrupted at 03:31:11 -- 9 seconds later. If the user had not interrupted, the agent would have dispatched 6 more review angles (the code-review skill uses 7 parallel finders), waited for all 7 to return, synthesized findings, and presented a review based on a code-quality framework not designed for skill `.md` files. The interrupt prevented the wrong review from producing findings that would then need to be discarded.

**L-2: User corrected scope before the full review ran**
The 67-file scope error was caught at 02:49:29 (user interrupt) -- after the count was stated but before the full diff was read and reviewed. If the user had accepted the 67-file count, the agent would have reviewed all 67 files (many of which belong to prior PR work, not this session's changes), spent significant context, and produced findings mixing old and new work. The interruption prevented 37+ minutes of wasted review.

**L-3: The git log output was available and correct -- the failure was interpretation, not data**
At event 40, the complete `git log --oneline main..HEAD` output was in the agent's context showing all 20 commits with PR-numbered commits visible. If the agent had read this output before running `wc -l`, it would have caught the scope inflation without user correction. The data was there; the gate to use it was not. This means the problem was entirely mechanical and preventable -- the correct data existed in context; only the gate to act on it was missing.

**L-4: No review conclusions were acted on from the wrong reviewer**
Because both user interruptions fired before any reviewer returned results, no findings from the wrong reviewer type (code-review) were presented to the user or applied to any files. The harm was limited to time cost (the 37-minute gap between correction and resumed review). No incorrect changes were made and no findings from a wrong reviewer influenced the session's conclusions.

---

## Part 4c: User Prompt Quality Review

**Pattern 1: "review the changes you have made" -- ambiguous on scope and reviewer type**

**Example (quoted):** "review the changes you have made"

**Effect:** The agent had to infer both (a) which files "the changes you have made" referred to on a 20-commit branch and (b) which reviewer type to use. It got both wrong: scope was `main..HEAD` (67 files, wrong) and reviewer was `code-review` (wrong for `.md` files). Both corrections required user interruption. The 37-minute gap between the first correction and the resumed review represents the cost.

**Recommendation:** Specify both scope and reviewer type explicitly: "Run the skill-reviewer on the 8 files from this session's postmortem work (the commits since 3415f79)." This eliminates both ambiguities. If the user does not know the correct reviewer type, specifying "the skill files I changed" at minimum constrains the domain.

---

**Pattern 2: "yes" with no reiteration after a 37-minute gap**

**Example (quoted):** User at 03:29:32 sends "yes" as the entire message, 37 minutes after the agent's last turn at 02:52:14.

**Effect:** After a 37-minute gap, "yes" is unambiguous (it answers "Shall I re-run the review against `3415f79..HEAD`?") but it carries no additional context about whether the user had changed intent or had additional constraints. The agent correctly interpreted it as approval. However, a longer gap combined with a one-word response creates a minimal-context resumption where the agent's prior plan (code-review framework, just with correct scope) remains active. The user may not have realized the wrong reviewer type was still in effect.

**Effect:** The agent resumed the code-review framework with the corrected scope without the user realizing the reviewer TYPE was still wrong. If the user had said "yes, but use the skill-reviewer not the code-reviewer," the second interruption at 03:31:21 would have been unnecessary.

**Recommendation:** After a gap of more than a few minutes, briefly restate the intent: "yes, re-run the review with correct scope using the skill-reviewer." This prevents plan-state drift where the agent's prior (wrong) plan is still active and the user's "yes" inadvertently approves it.

---

**Pattern 3: "why are you running the code reviewer?" asked twice**

**Example (quoted):** 03:31:21 "why are you running the code reviewer?" (first ask); 03:37:08 "why are you running the code reviewer?" (repeated, identical).

**Effect:** The first ask at 03:31:21 was during an agent interruption. The agent was interrupted mid-dispatch and did not have a chance to respond. The user sent it again at 03:37:08, 5.5 minutes later. The repetition was necessary given the interrupt mechanics, not a prompt quality issue per se -- but the pattern shows that interrupting a mid-dispatch agent creates a window where the user's correction is not acknowledged until the agent finishes its current operation.

**Recommendation:** This is more of a harness interaction pattern than a prompt quality issue. No change needed to the prompt content. However, users should expect that interrupting a mid-dispatch agent requires repeating the correction once the agent's current turn completes.

---

## Part 5: Action Items

| # | Root Cause / Factor | Action Item | Strength | Target File |
|---|---------------------|-------------|----------|-------------|
| 1 | No scope-verification gate before reporting branch diff count | Add to `code-review` or `review` SKILL.md (and/or `using-git-worktrees`): "Before reporting the number of files changed on a branch, inspect `git log --oneline base..HEAD` output. If any commits appear to predate this session's work (PR-numbered, prior-session commit messages), confirm which commit is the correct base for this session's changes before running `wc -l`. Reporting a diff count without scope verification is a confidence-without-evidence claim." | [+] STRONG (inspection gate before count) | `skills/using-git-worktrees/SKILL.md` Red Flags section |
| 2 | No reviewer-type gate before invoking any review command | Add to `subagent-driven-development/SKILL.md` 2-Stage Review Protocol: "BEFORE invoking any reviewer command or skill: identify the file types in scope. If any files are skill `.md` files: use `skill-reviewer`. If any files are code or config: use `code-quality-reviewer`. Invoking `code-review` for `.md` skill files is always wrong." Add to Red Flags table: `\| "I'm about to run /code-review" \| STOP. Are the files skill .md files? If yes: use skill-reviewer, not code-review. \|` | [+] STRONG (Red Flag, fires on recognition) | `skills/subagent-driven-development/SKILL.md` Red Flags table |
| 3 | Self-assessment independence gate has no multi-session append protocol | Add to `session-postmortem/references/POSTMORTEM_STRUCTURE.md` External Reviewer Protocol, Step 2: "If `self-assessment.md` already exists from a prior session: do NOT read the file to find an append anchor. Write the new section heading from memory using today's date and session ID: `## Session Self-Evaluation (YYYY-MM-DD -- [task description])`. Append this heading and all content below it using the shell append operator without reading the existing file. Reading the prior session's content to find an anchor violates the independence gate." | [+] STRONG (protocol addition, eliminates the read-before-append pattern) | `skills/session-postmortem/references/POSTMORTEM_STRUCTURE.md` |
| 4 | verification-before-completion announced without Skill tool invocation | Add to `honesty/SKILL.md` or `verification-before-completion/SKILL.md` Rationalization table: `\| "I am using skill X" (announced from memory, no Skill tool call) \| Announcing a skill from memory is not equivalent to invoking it. The skill's gate functions fire on the Skill tool call, not on the announcement. If the skill's enforcement path matters, invoke it via the Skill tool. \|` | [+] STRONG (rationalization table, counters the announcement-without-invocation pattern) | `skills/honesty/SKILL.md` Rationalization Prevention |
| 5 | code-review adapted to wrong domain instead of replaced | Add to `code-review` SKILL.md or skill invocation instructions: "BEFORE PROCEEDING: check the file types in scope. If the primary files being reviewed are skill `.md` files, STOP. Code-review is for code and config. Do not adapt its framework to skill files. Use skill-reviewer." | [+] STRONG (gate at skill entry point) | Wherever `code-review` SKILL.md BEFORE PROCEEDING is defined |

---

## Iron Law Compliance Check

| Law | Followed | Evidence | Notes |
|-----|----------|----------|-------|
| TDD (no prod code without test) | N/A | Session produces only .md files | Not applicable |
| Verification before completion | [+] | git diff run before commit at 02:39:45; diff confirmed before committing | Edit -> verify -> commit sequence correct |
| Root cause before fixes | [+] | No fixes applied before root cause identified in either failure | User corrections led to analysis, not to immediate retries |
| Conventional commits | [+] | 220b253 commit: `docs(sdd): add RC1 known limitation caveat and tighten breakout gate` | Matches established format |
| Skills loaded before acting | [-] | code-review loaded at 02:48:37 for .md skill files (wrong skill); verification-before-completion announced at 02:39:34 but no Skill tool call | Two violations: wrong skill loaded, correct skill announced without invocation |
| Commitments kept or acknowledged | [+] | Agent committed to Option B (RC1 caveat, no proof run); committed and pushed 220b253; no announced commitments dropped | |

---

## Self-Assessment Discrepancies

**Discrepancy 1: Self-assessment describes the wrong-reviewer mistake as discovered after the 67-file analysis. The log shows the wrong reviewer was invoked BEFORE the 67-file mistake.**

Self-assessment: "Mistake 1: Wrong diff scope... Mistake 2: Wrong reviewer type." Implies these happened in order: wrong scope first, then wrong reviewer.

Log: code-review was invoked at 02:48:37 (before any diff command). The 67-file count was stated at 02:49:21. The wrong reviewer type preceded the wrong scope count by 44 seconds. Both mistakes are part of the same code-review invocation -- the reviewer was wrong type and the scope was wrong -- but the sequencing matters for root cause analysis.

**Discrepancy 2: Self-assessment says "False confidence claims: 1 (67-file count presented as fact without scope verification)." The log shows the agent also announced using verification-before-completion without invoking the Skill tool.**

The verification-before-completion announcement at 02:39:34 is a confidence claim about using a skill ("I am using the verification-before-completion skill") without the supporting tool call. The actual verification behavior was correct (git diff before commit), but the announcement implied the skill's gate function was active when it was not. This is a second confidence claim without full evidence: two in the session, not one.

**Discrepancy 3: Self-assessment does not mention the self-assessment independence gate concern (reading existing file before appending).**

The self-assessment was written by the agent that performed the read, so the omission is expected -- the agent would not flag its own independence gate behavior as a violation. The external log shows the Read at 03:39:39 preceded the Bash append at 03:39:53.

---

## Verdict: NEEDS IMPROVEMENT

**Rationale:** Two user corrections were required in a single context window, both from the same root invocation (code-review for .md skill files). The 67-file count was stated as fact when the git log data to detect the scope inflation was already in the agent's context -- the failure was not missing data but a missing gate to use data that was present. The wrong reviewer type persisted through scope correction: the agent corrected the scope but not the reviewer type, and only recognized the second mistake when the user asked "why are you running the code reviewer?" for the second time.

What prevents this from being SYSTEMIC ISSUE: both mistakes were correctly diagnosed once identified, no incorrect changes were applied to files, and the session concluded with correct postmortem process (self-evaluation -> external reviewer dispatch in the right order). The failures were scope and reviewer type -- correctability errors, not process bypass errors.

The most actionable finding is Action Item 2: a Red Flag in SDD SKILL.md that fires when the user says "review" and the files are `.md` skill files. That one structural change would have prevented both the wrong reviewer invocation and the downstream scope mismatch from compounding into two separate user corrections.

---

*Report written by external reviewer subagent. No session memory. Evidence cited from events.jsonl.*
*Events log: `/root/.claude/projects/-home-user-story-to-ship/bc9fc4ed-63b8-5f0a-a18a-9796acd15c67.jsonl`*
