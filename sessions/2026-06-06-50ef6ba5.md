# Session Postmortem: Greenfield App Skills Planning

## External Reviewer Note

Reviewer: external subagent -- cold read of events.jsonl, no session memory
Session: 50ef6ba5-29ba-5eb3-9763-3d54e7bc25ef
Log events analyzed: 293
Self-assessment reviewed: NO -- no self-assessment file found at any standard path. The agent's self-evaluation exists only in the message stream (event 267 assistant text), not as a written file.
Conflicts with self-assessment: N/A -- no file to compare against. The stream-only self-evaluation is itself a finding.

---

### Summary

The agent planned 5 INVEST-validated user stories for a greenfield app skills suite, ran Two Three Amigos ceremonies (Discovery and Refinement), resolved 7 context questions and 2 decision questions from users, wrote a Feature Specification to plan.md, created 5 GitHub issues, updated 3 skill files during self-evaluation, then removed plan.md. The session ran approximately 03:12--14:03 (UTC) on 2026-06-06 with a ~9.5 hour gap (04:22 to 13:30) during Refinement AskUserQuestion wait.

---

## Part 1: Timeline

```
03:12 - User requests greenfield skill stories -- no mention of Three Amigos, planning mode, or output format
03:13 - Agent loads session-bootstrap, user-story-generator, user-story-estimation -- correct proactive loading
03:13 - Agent reads PV_PROJECT_CONTEXT.md (Particle-Viewer project context for a non-Particle-Viewer session)
03:14 - Agent dispatches C2 wiki research subagent in parallel with story template reads -- correct parallelism
03:15 - Agent sends AskUserQuestion with 3 clarifying questions -- acting as informal Discovery substitute
03:21 - Agent generates 4 full stories with ACs and estimates without loading three-amigos -- GATE MISS
03:25 - User adds "lets add the repo setup with a basic build smoke test pipeline" -- scope addition mid-generation
03:26 - Agent checks repo structure instead of clarifying ambiguity -- interprets "add" as "implement" then checks
03:26 - User interrupts the repo inspection
03:27 - User clarifies: add it to the greenfield skill, not implement it -- Story 5 defined
03:27 - Agent reloads user-story-generator for the fifth story -- redundant skill reload
03:28 - Agent generates Story 5 (bootstrapping) -- still without three-amigos loaded
03:30 - User states: "we arent here to build, we are here to plan. Mechanical Analysis: were you going to invoke the amigos? did you have that in your plan?"
03:30 - Attachment event fires (hook with system context) -- large output; agent appears not to respond
03:37 - User sends "Continue from where you left off" -- 7 minutes later, agent replies "No response requested"
03:37 - User asks "are you able to process the last message?" -- second follow-up required
03:38 - Agent acknowledges gap: "I did not invoke the three-amigos skill" -- loads three-amigos (event 85)
03:38 - Agent reads CEREMONIES.md, reads amigo.md -- correct pre-dispatch reads
03:39 - Agent writes plan.md (5 stories for amigos to read) -- correct
03:40 - Agent creates 3 worktrees and dispatches Discovery amigos in parallel -- correct
03:42 - Two amigos return NEEDS_CONTEXT (Business + Tester at events 112, 113)
03:42 - Stop hook fires: "untracked files in repository" -- plan.md not yet committed
03:43 - Agent commits plan.md while Developer amigo still running -- responding to stop hook mid-wait
03:44 - Developer amigo completes (event 130) -- all 3 return NEEDS_CONTEXT
03:45 - Agent synthesizes 7 blocking questions -- correct protocol (all 3 before acting)
03:54 - User answers all 7 questions in one message
03:54 - Agent writes Feature Specification to plan.md
03:55 - Agent loads versioning skill before commit -- correct proactive loading
03:55 - Agent commits and pushes (event 155, 157)
03:56 - Agent announces state; waits for user

[~9.5 hour gap -- AskUserQuestion for Refinement decision pending]

13:30 - User says "fire the refinement now"
13:13 - Agent creates 3 Refinement worktrees and dispatches 3 amigos simultaneously
14:14 - Business and Tester amigos immediately BLOCKED -- worktree self-check failed (git rev-parse returned main repo, not worktree path)
14:16 - Developer amigo returns CONDITIONS (correct)
14:16 - Agent re-dispatches Business and Tester with explicit "cd {{WORKTREE_PATH}} &&" prefix
14:17 - Business amigo returns CONDITIONS
14:21 - Tester amigo returns CONDITIONS
14:21 - Agent synthesizes; presents 2 user decisions (Story 3 form, Story 5 stacks)
14:22 - AskUserQuestion sent

[another wait -- user responds at 13:30:35 next calendar day? -- No, same day: session gap filled by AskUserQuestion blocking]

13:30 - User answers both decisions
13:31 - Agent applies Refinement conditions, rewrites plan.md
13:33 - Agent commits and pushes
13:39 - User asks: "mechanical question: why are you suggesting to read from a file instead of talking directly to github and creating an issue?"
13:39 - Agent admits: "I defaulted to plan.md ... I didn't proactively consider the alternative"
13:42 - User confirms GitHub issues
13:42 - Agent loads mcp__github__issue_write tool -- correct
13:43-13:44 - Agent creates 5 GitHub issues -- SEQUENTIAL, not parallel, despite claiming "in parallel" (events 219-228: 17-second gaps)
13:50 - User requests self-evaluation
13:50 - Agent loads self-evaluation skill -- correct
13:51 - Agent reads 3 skill files, identifies 4 lessons, makes 6 targeted edits, commits
13:53 - Agent presents self-evaluation in message stream only -- no file written
14:00 - User requests: remove plan.md and dispatch postmortem agent
14:00 - Agent removes plan.md and reads session-postmortem skill in parallel -- correct
14:01 - Agent dispatches external reviewer subagent (async) -- correct
14:03 - Agent announces reviewer is running, will not assess until return
```

---

## Part 2: Root Cause Analysis

### Failure 1: Three Amigos gate not fired before story generation

**Proximate cause:** Agent generated 4 full stories with acceptance criteria (event 53) without loading or invoking three-amigos.

**5 Whys:**
- Why? The user-story-generator SKILL.md (pre-session) had no explicit "generate 2+ stories with new ACs -> STOP, load three-amigos" trigger in its Red Flags section.
- Why was that trigger missing? The rationalization table covered INVEST-specific excuses but not the ceremony-skip excuse.
- Why wasn't the three-amigos trigger rule in the description field of user-story-generator? The skill's `description` field lists when to invoke the skill, not when to invoke other skills from within it. There was no cross-skill gate.
- Why did AskUserQuestion substitute for Discovery? The agent explicitly treated it as equivalent -- "I used AskUserQuestion for clarification, which covers some Discovery ground informally" (event 84 thinking block, event 90).
- **Root cause:** No gate in user-story-generator's Red Flags section stops story generation when new unclear ACs are being authored. The cross-skill trigger was absent from the skill that fires before the trigger opportunity arrives.

[EVIDENCE: 2026-06-06T03:21:00 -- event 53 assistant message generating 4 complete stories with full ACs, no preceding Skill:three-amigos call]

### Failure 2: Agent failed to respond to user correction (event 76) for 7+ minutes

**Proximate cause:** User sent "we arent here to build, we are here to plan" at 03:30; agent replied "No response requested" at 03:37 after user sent a follow-up.

**5 Whys:**
- Why did the agent not respond immediately? An attachment event (event 77 -- hook output) fired simultaneously with the user message. The hook output was a large context attachment (11.5KB, truncated to 2KB preview). The agent appears to have processed only the attachment and not the user message.
- Why did the agent say "No response requested"? At event 79, when user sent "Continue from where you left off," the agent replied "No response requested" -- this indicates the agent may have been processing the hook context injection and lost track of the pending user message.
- Why did the hook attachment suppress the user message? This is an infrastructure behavior; the attachment event injected a system context block that may have filled the response slot.
- **Root cause:** Infrastructure interaction between stop hook context injections and user message processing created a dropped-message condition. The agent did not acknowledge the dropped message or flag an anomaly -- it only responded when the user asked again at event 80.

[EVIDENCE: 2026-06-06T03:30:02 -- event 76 user message; 2026-06-06T03:37:50 -- event 79 "No response requested"; 2026-06-06T03:37:50 -- event 80 user "are you able to process the last message?"]

### Failure 3: Refinement Ceremony worktree dispatch failure (2 of 3 amigos BLOCKED)

**Proximate cause:** Business and Tester amigos for Refinement returned BLOCKED immediately -- `git rev-parse --show-toplevel` returned `/home/user/story-to-ship` instead of the worktree path.

**5 Whys:**
- Why did agents run in the main repo instead of the worktree? The amigo.md template instructed `git rev-parse --show-toplevel` but not `cd {{WORKTREE_PATH}} &&` before it. Agents start with cwd reset to main repo between bash calls.
- Why was the Discovery ceremony unaffected? Discovery was the first ceremony; no pattern for the cwd reset behavior had yet been established.
- Why wasn't the cwd reset behavior documented in amigo.md? It was not previously observed -- this was the first session where the behavior surfaced as a failure.
- **Root cause:** The amigo.md template did not enforce a `cd` to the worktree before the self-check. The self-check was designed to verify the cwd, but the cwd was never set. This caused 2 wasted subagent runs (events 168, 171) before re-dispatch with corrected prompts (events 176, 177).

[EVIDENCE: 2026-06-06T04:14:21 -- event 168 Business amigo BLOCKED; 2026-06-06T04:14:42 -- event 171 Tester amigo BLOCKED; both report main repo path instead of worktree path]

### Failure 4: GitHub issues created sequentially despite agent claiming "in parallel"

**Proximate cause:** Agent announced "Creating all 5 issues in parallel" (event 218) but timestamp evidence shows each issue was created ~17 seconds after the previous one.

**5 Whys:**
- Why were they sequential? The agent used separate sequential mcp__github__issue_write calls in the same turn (events 219, 221, 223, 225, 227) rather than using an async Task or parallel Agent pattern.
- Why did the agent claim "in parallel"? The assistant message at event 218 made the claim before the calls executed. This was an announced intent that the tool invocation pattern did not fulfill.
- Why didn't parallelism fire? The GitHub MCP tool calls in a single turn appear to be executed sequentially by the harness, not in parallel. The agent did not dispatch a Task or use parallel Agent calls to achieve true parallelism.
- **Root cause:** "In parallel" for MCP tool calls in a single assistant turn is not the same as parallel execution. The agent overstated the execution model. The claim was not verified against timing evidence.

[EVIDENCE: Events 219, 221, 223, 225, 227 timestamps: 13:43:17, 13:43:34, 13:43:51, 13:44:11, 13:44:31 -- 17-second sequential gaps]

### Failure 5: Self-evaluation result not written to disk

**Proximate cause:** The self-evaluation output (4 lessons, 3 skill files updated) was presented only in the message stream (event 267 assistant text). No postmortem.md or self-assessment file was written before the session ended.

**5 Whys:**
- Why wasn't a file written? The self-evaluation skill loaded (event 235) and the agent ran through lessons and skill edits, but the skill's "Write Gate" requirement did not produce a written self-assessment file.
- Why wasn't the write gate enforced? The session-postmortem skill specifies the write gate; the self-evaluation skill may not have an equivalent file-creation requirement. The agent applied lessons via skill edits but did not write a session record.
- **Root cause:** The self-evaluation skill does not enforce writing its findings to a file. The output existed only in context, which is ephemeral. The postmortem skill then required an external reviewer to work from events.jsonl rather than a complementary self-assessment file.

[EVIDENCE: No postmortem.md or self-assessment.md found in /home/user/story-to-ship/ at time of external review; event 267 shows self-evaluation output in message stream only]

### Near-Miss 1: Stop hook triggered commit during active amigo wait

**What happened:** Plan.md was not committed before Discovery amigos were dispatched. Stop hook fired at 03:42 (event 117) while the Developer amigo was still running. Agent committed plan.md (event 123) while waiting for the third verdict.

**Observation:** The protocol says "collect all three verdicts before acting on any" (three-amigos SKILL.md step 4). The commit was not synthesis-acting on amigo findings -- it was responding to the stop hook for a different reason. The commit was correct in isolation. However, it represents a race condition: if the commit had failed or caused a conflict, the amigo workspace could have been disrupted.

**Near-miss, not failure:** The commit succeeded without affecting the worktree content the amigos were reading. The agent correctly stated "Still waiting on the Developer amigo -- will synthesize all three verdicts once it returns" (event 127), demonstrating the wait protocol was preserved. But the stop hook interrupted the amigo wait and caused unplanned work mid-ceremony.

[EVIDENCE: 2026-06-06T03:42:53 -- event 117 stop hook; 2026-06-06T03:43:05 -- event 123 commit; 2026-06-06T03:44:32 -- event 130 Developer amigo returns]

### Near-Miss 2: PV_PROJECT_CONTEXT.md read for a non-Particle-Viewer session

**What happened:** The user-story-generator SKILL.md step 1 instructs loading `references/PV_PROJECT_CONTEXT.md`. The agent read this file (event 47) for a session about story-to-ship greenfield skills -- not about the Particle-Viewer project. The file explicitly scopes itself to Particle-Viewer.

**Observation:** The agent read this file and then proceeded without acting on the mismatch. This is rationalization by omission -- the scope gate in the file should have fired a "this is not PV scope" alert, but the agent silently continued. The stories produced were coherent with the actual request, so the wrong-context read had no practical effect. But the read wasted context and the scope gate was inactive.

[EVIDENCE: 2026-06-06T03:14:13 -- event 47 Read PV_PROJECT_CONTEXT.md; session subject was story-to-ship greenfield skills, not Particle-Viewer]

---

## Part 3: Contributing Factors

**CF-1: No cross-skill trigger from user-story-generator to three-amigos**
The user-story-generator skill's Red Flags section listed INVEST violations as stops but did not mention the three-amigos trigger. A developer generating stories could complete all of user-story-generator's checklist without ever being pointed to three-amigos. This is a structural gap -- the gate is in the wrong skill. (Fixed in self-evaluation, but only after the session demonstrated the failure.)

**CF-2: AskUserQuestion creates a false sense of Discovery completion**
The agent used AskUserQuestion for 3 clarifying questions (event 50) and interpreted the answers as "Discovery-equivalent." The three-amigos rationalization table (pre-session) did not explicitly list "AskUserQuestion substitutes for Discovery" as a named excuse. Because this excuse pattern was unnamed, the agent could use it without triggering any internal alarm. (Fixed in self-evaluation, but the damage -- 5 stories with unvalidated ACs -- had already been done.)

**CF-3: Worktree self-check design assumes cwd is correct**
The amigo.md template (pre-session) ran `git rev-parse --show-toplevel` as the self-check but had no `cd` command. Agent processes start with cwd reset to the main repo. This was a latent failure in the template that required a live failure to surface.

**CF-4: Session scope jumped from "planning" to "building" framing**
The user's initial request was "I want to build out a few stories." The word "build" is ambiguous -- it means author stories, not implement code. The agent treated it as story authoring but then, when the user asked about "adding repo setup," the agent interpreted "add" as potentially implementing it (event 58: "Let me check what's already in the story-to-ship repo before I go further -- 'lets add' could mean write another story OR actually do it now"). This ambiguity resolution required an interruption.

**CF-5: Stop hook context injection and user message race**
The stop hook fires context into the attachment stream. When a user message and a hook attachment arrive at similar times, the attachment may suppress or delay the agent's response to the user message. This contributed to the 7-minute gap and the "No response requested" anomaly.

**CF-6: "In parallel" claimed without verifying execution model**
The agent announced parallel issue creation without verifying whether sequential MCP tool calls in a single turn constitute parallel execution. No verification gate exists for this claim type.

---

## Part 4: What Went Well

**W-1: Session-bootstrap loaded proactively, correctly**
The agent loaded session-bootstrap first (event 9), then derived required skills from it (user-story-generator, user-story-estimation). This was the correct order with no retroactive loading.

**W-2: Three Amigos protocol followed correctly once invoked**
After the gate was missed and then corrected, the agent followed three-amigos protocol precisely: read CEREMONIES.md (event 91), read amigo.md (event 96), wrote stories to disk before dispatching (event 102), created 3 worktrees (event 105), dispatched all 3 simultaneously (events 109-111), collected all 3 verdicts before acting (events 112-113, 130-133), and cleaned up worktrees after.

**W-3: Discovery verdict collection was disciplined**
When two of three Discovery amigos returned NEEDS_CONTEXT at 03:42, the agent did not act on partial results. It explicitly stated "waiting for the Developer amigo to return before synthesizing" (event 116). When the Developer amigo returned (event 130), it then synthesized all three. The "collect all before acting" gate fired correctly.

**W-4: Versioning skill loaded before commit**
Before the Feature Specification commit (event 155), the agent proactively loaded the versioning skill (event 149). This was proactive, not retroactive.

**W-5: Self-identified the AskUserQuestion rationalization explicitly**
When confronted by the user, the agent's thinking block (event 83) accurately diagnosed the gap: "I need to recognize where I skipped a step in the workflow. Since we're already past the planning phase with stories written, the Review ceremony would be more appropriate now." The agent did not rationalize its way past the correction -- it loaded three-amigos immediately.

**W-6: Worktree re-dispatch was executed immediately and correctly**
When 2 of 3 Refinement amigos BLOCKED, the agent identified the root cause (cwd not set to worktree), patched the prompt with explicit `cd {{WORKTREE_PATH}} &&` prefix (events 176-177), and re-dispatched without re-running the third (Developer) amigo that had already returned. This was efficient and correct.

**W-7: Postmortem skill loaded and external reviewer dispatched**
The agent loaded session-postmortem (event 278), located the events log (event 286), and dispatched the external reviewer as a separate subagent (event 290). It correctly stated it would not summarize or assess until the reviewer returned (event 292).

**W-8: GitHub issues > plan.md recognized and corrected**
When the user questioned why the agent was reading from a file instead of creating GitHub issues directly (event 204), the agent gave an honest answer -- "I defaulted to plan.md ... I didn't proactively consider the alternative" (event 208) -- and immediately proposed GitHub issues. This was a clean self-correction with honest attribution.

---

## Part 4b: Where We Got Lucky

**L-1: AskUserQuestion happened to cover critical information despite being a wrong-process substitute**
The agent used AskUserQuestion (event 50) instead of Discovery for initial clarification. The 3 questions asked ("domain knowledge input?", "vertical slice vs. separate?", "how does context flow?") partially overlapped with what Discovery would have produced. If the questions had been poorly chosen, the stories would have had unresolvable ambiguities that only Discovery would have surfaced. The agent got lucky: the informal questions captured enough context to write coherent stories. Discovery still surfaced 7 more items those questions didn't catch.

**L-2: Plan.md commit during Discovery wait did not corrupt amigo workspaces**
The stop hook forced a commit of plan.md at 03:43 (event 123) while the Developer amigo was still running. The amigos were reading plan.md from their worktrees. If the commit had changed plan.md in a way that conflicted with the worktrees' views of the file, the Developer amigo could have returned findings based on inconsistent state. The commit only added plan.md (it was previously untracked) -- it did not modify content the amigos were already reading. This was structurally safe by luck, not by protocol.

**L-3: Discovery ceremony wasn't run on a fully wrong set of stories**
All 4 initial stories (event 53) were generated from AskUserQuestion answers. If the user's answers had been ambiguous or incomplete, the Discovery amigos would have returned NEEDS_CONTEXT on badly-scoped stories, requiring a full story rewrite before proceeding. The stories happened to be coherent enough that Discovery's NEEDS_CONTEXT focused on behavioral detail gaps, not fundamental scope problems. The ceremony still surfaced 7 blocking items -- but it could have been worse.

**L-4: Sequential GitHub issue creation matched the user's expectation**
The agent claimed "in parallel" (event 218) but created issues sequentially. The user had already confirmed "yes" (event 210) and then saw the "All 5 issues created" table (event 229) without inspecting timestamps. The user's approval of the outcome did not distinguish between "parallel" (faster) and "sequential" (slower). The inflated claim went unchallenged. If a timeout had occurred on any one issue creation, the partial-success state would not have been correctly handled for the "parallel" model.

---

## Part 4c: User Prompt Quality Review

**Pattern 1: Scope addition mid-generation**

**Example (quoted):** "lets add the repo setup with a basic build smoke test pipeline, documentation, and gitignore. Hello world would be nice but can be complex" (event 54, 03:25 -- after 4 stories were already generated at 03:21)

**Effect:** The agent spent 2 minutes inspecting the repo structure trying to understand whether "add" meant story authoring or implementation (events 58-62). The user then had to interrupt and clarify (event 64, 65). One tool call was wasted (repo inspection) and the session lost 5 minutes.

**Recommendation:** Add the scope item before or with the initial request. If adding scope mid-session, signal the mode explicitly: "Add a 5th story about X" rather than "lets add X" which is ambiguous between "story" and "implementation."

---

**Pattern 2: Implicit session mode not stated**

**Example (quoted):** "we arent here to build, we are here to plan. I should execute all of these with a fresh context to accurately build this functionality out." (event 76)

**Effect:** The session mode (planning only, no implementation) was not stated at session start. The agent treated story authoring as the task but did not have a clear signal to avoid generating implementation-flavored commentary or checking existing workflows. The correction at event 76 arrived after 5 stories were already generated and Story 5 was complete.

**Recommendation:** State session mode at the top: "This is a planning-only session. No implementation. Stories go to GitHub issues." This prevents ambiguity resolution attempts that cost interruptions.

---

**Pattern 3: Multi-part answer with no structure labels**

**Example (paraphrased):** Event 138 -- user answered 7 questions in a single message using letter labels (A through G) but with no explicit question numbering or formatting. Several answers were partially ambiguous: "C) it should flow, like how this should have flowed into the 3 amigos" (unclear which specific flow behavior), "d) Ive never used it, I want to try it, I dont know the language syntax" (unclear what "it" refers to without reading D's question).

**Effect:** The agent resolved the ambiguities correctly (event 142 correctly maps all 7), but the "it" in answer D required inference. In a different session state, this could have produced a wrong AC.

**Recommendation:** For multi-part answers, quote the question being answered: "A (output mode): write to disk." This eliminates pronoun ambiguity under context pressure.

---

**Pattern 4: Vague trigger for a ceremony ("fire the refinement now")**

**Example (quoted):** "fire the refinement now. is this for all 5 stories?" (event 160)

**Effect:** The agent correctly identified the ceremony (Refinement) and scope (all 5 stories). No misdirection resulted. But the prompt was effectively an instruction without context -- the agent had to verify from plan.md that the precondition (Discovery ran, Feature Specification present) was met (event 164). If the precondition had not been met, this prompt would have caused the wrong ceremony.

**Recommendation:** The user can instead ask: "Is it time to run Refinement?" and let the agent verify preconditions explicitly before firing. This makes the agent's pre-ceremony check visible and correctable.

---

## Part 5: Action Items

| # | Root Cause / Factor | Action Item | Strength | Target File |
|---|---------------------|-------------|----------|-------------|
| 1 | Three-amigos gate not in user-story-generator | Add to Red Flags: "Generating 2+ stories with new or unclear ACs without loading three-amigos -> STOP. Load `three-amigos` Ceremony 1 before generating any acceptance criteria." | [+] STRONG (Red Flag -> STOP) | `skills/user-story-generator/SKILL.md` -- Red Flags section |
| 2 | AskUserQuestion treated as Discovery substitute | Add to Rationalization Prevention: "AskUserQuestion substitutes for Discovery -> AskUserQuestion is informal Q&A. Discovery produces a Feature Specification with field optionality, invocation paths, and behavioral ACs under three personas. They are not equivalent." (Note: partially added in self-eval; verify it covers the specific substitution claim, not just a general statement) | [+] STRONG (rationalization table) | `skills/user-story-generator/SKILL.md` -- Rationalization Prevention |
| 3 | amigo.md self-check requires cwd to be set | Add before worktree self-check: "```bash\ncd {{WORKTREE_PATH}} && git rev-parse --show-toplevel\n```" Note: this was applied in self-evaluation (event 250). Verify the fix is present and covers the exact failure path. | [+] STRONG (gate/system change) | `agents/amigo.md` -- Worktree Self-Check (already patched; verify completeness) |
| 4 | GitHub issues created sequentially despite "in parallel" claim | Add to honesty skill or execution skill: "Do not claim 'in parallel' for sequential tool calls in a single turn. Parallel execution requires Task dispatch or parallel Agent calls. Verify the execution model before announcing it." | [+] STRONG (rationalization table) | `skills/honesty/SKILL.md` or `skills/execution/SKILL.md` -- Rationalization Prevention |
| 5 | Self-evaluation output not written to disk | Add to self-evaluation SKILL.md a Write Gate section: "Before announcing self-evaluation complete, write the findings summary to `self-assessment.md` in the session workspace. A self-evaluation that exists only in the message stream is not a self-evaluation." | [+] STRONG (gate/system change) | `skills/self-evaluation/SKILL.md` -- add Write Gate |
| 6 | PV_PROJECT_CONTEXT.md scope check inactive for non-PV sessions | Add to user-story-generator BEFORE PROCEEDING step 1: "If this session is not about the Particle-Viewer project, skip PV_PROJECT_CONTEXT.md -- it is PV-specific. Use the actual project context from the repo README or user description." | [+] STRONG (gate/system change) | `skills/user-story-generator/SKILL.md` -- BEFORE PROCEEDING step 1 |
| 7 | Stop hook interrupts agent mid-ceremony without protocol | Add to three-amigos SKILL.md Worktree Dispatch Protocol: "If a stop hook fires during an active amigo wait: respond to the hook only if the action is non-destructive to worktree state (e.g., committing an untracked file). Log the interruption. Do not synthesize amigo results until all verdicts are received. Resume the wait after handling the hook." | [+] STRONG (gate/system change) | `skills/three-amigos/SKILL.md` -- Worktree Dispatch Protocol |
| 8 | "In parallel" execution model not verified before claim | Add to dispatching-parallel-agents skill: "MCP tool calls in a single assistant turn execute sequentially. Parallel execution requires separate Task dispatches or parallel Agent calls. Do not announce 'in parallel' for same-turn tool call sequences." | [+] STRONG (rationalization table) | `skills/dispatching-parallel-agents/SKILL.md` |

---

## Iron Law Compliance Check

| Law | Followed | Evidence | Notes |
|-----|----------|----------|-------|
| TDD (no prod code without test) | N/A | Planning session only; no code written | Not applicable |
| Verification before completion | [+] Partial | Agent verified amigo verdicts, commits, and pushes. Claimed "in parallel" without verifying execution model (Failure 4). | One case of unverified claim about execution model |
| Root cause before fixes | [+] | Agent identified worktree cwd as root cause before re-dispatching Refinement amigos | Correctly diagnosed before patching |
| Conventional commits | [+] | All 5 commits use conventional format: docs(planning), docs(greenfield) x2, fix(skills), chore | Versioning skill loaded before each commit |
| Skills loaded before acting | [-] | three-amigos loaded AFTER 5 stories with ACs were generated (event 85 after event 53) | Core failure of the session; retroactive load |
| Commitments kept or acknowledged | [+] Partial | Agent correctly waited for all 3 amigo verdicts before synthesis. Drop-and-recover on event 76 response (7-minute gap, required 2 user follow-ups). | One dropped message recovered with user prompting |

**Red Flag Count:**
- Agent loaded skills after acting in their domain (retroactive three-amigos load): YES
- User had to correct the same behavior more than once: NO (one correction, one follow-up for the missed response)
- Agent dropped an announced commitment without acknowledging it: YES (event 76 response dropped without acknowledgment)
- Postmortem report not written to file before completion: N/A (external reviewer writing this report now)
- Self-evaluation output not written to disk: YES
- "In parallel" claim made without verifiable process: YES (GitHub issues)

**Red Flag count: 4** -- Three or more = SYSTEMIC ISSUE per the skill definition.

---

## Verdict: SYSTEMIC ISSUE

**Rationale:** Four red flags are present:
1. Skills loaded retroactively after acting in their domain (three-amigos loaded after 5 stories generated)
2. Agent dropped a user message without acknowledgment (event 76, recovered only after user sent 2 follow-ups)
3. Self-evaluation output not written to disk
4. "In parallel" claim made for sequential execution

These are not isolated lapses. They represent: a missing cross-skill gate (user-story-generator -> three-amigos), an infrastructure interaction that the session protocol does not handle, and a systematic pattern of announcing outcomes without verifying the execution model. The three-amigos skip in particular is structural: the rationalization ("AskUserQuestion covered it") was available to the agent because the named excuse was absent from the skill file at the time of the session. That is a skill gap, not a one-time error.

The self-evaluation identified 4 lessons and updated 3 files. This is commended -- the self-correction was real and targeted. But the self-evaluation missed: the sequential-vs-parallel GitHub issue claim, the PV_PROJECT_CONTEXT.md scope mismatch, and the stop-hook-during-ceremony race condition. The external review found 4 additional action items the self-evaluation did not surface.

Action Items 1, 4, 5, and 8 are highest priority and were not addressed by the self-evaluation.
