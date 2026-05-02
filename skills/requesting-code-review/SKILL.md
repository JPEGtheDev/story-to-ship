---
name: requesting-code-review
license: MIT
description: Use when preparing to request a code review on a PR or change.
---

## Iron Law

```
REVIEWS ARE TARGETED, NOT CEREMONIAL. YOU MUST STATE WHAT TO LOOK FOR IN EVERY REVIEW REQUEST.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the requesting-code-review skill to prepare a review request for [PR/change]."

---

## BEFORE PROCEEDING

- [ ] CI is green on the branch
- [ ] `verification-before-completion` gate has been run in this session
- [ ] PR description is complete (see `finishing-a-development-branch` Step 4)
- [ ] You have reviewed your own diff and addressed obvious issues

✓ All met → proceed to request review
✗ Any unmet → resolve all unmet items before requesting review

Requesting review against a red CI or an incomplete PR description wastes the reviewer's time and erodes trust.

---

## Selecting What to Review

Not all review is equal. State explicitly in the review request:

1. **What you most want reviewed** — correctness, design, test coverage, performance?
2. **What you are NOT asking for review on** — style, formatting (CI handles this), unrelated patterns
3. **Any areas you are uncertain about** — naming these invites the reviewer to focus where their input has highest value

**Template:**
```
## Review focus
- [ ] [Specific concern 1 — e.g., "Is the error handling in SDL3Context::init() complete?"]
- [ ] [Specific concern 2 — e.g., "Does the mock usage in test X correctly isolate the unit?"]

## Not requesting review on
- Formatting (enforced by CI)
- [Other explicitly out-of-scope areas]
```

---

## Agent Review Dispatch

For non-trivial PRs, dispatch code review agents before requesting human review:

**Rule: one agent per file changed.**

```
# For each changed file, dispatch:
task agent_type="code-review" prompt="
Review [file path] changed in this PR.
SHA: [commit SHA]
Focus: [specific concern for this file]
Return: list of issues by severity (BLOCKER / CONCERN / SUGGESTION)
"
```

**Collect all agent results before acting on any of them.** A BLOCKER from any agent must be resolved before requesting human review.

**Agent review does NOT replace human review** — it catches the mechanical issues so human review can focus on design and intent.

---

## SHA-Based Dispatch

Always include the commit SHA in review requests and agent dispatches. This ensures:

1. The reviewer knows exactly what they are reviewing
2. Review comments are anchored to a specific state — not a moving target
3. If the branch advances after review is requested, the SHA makes that visible

```bash
# Get current HEAD SHA for dispatch
git rev-parse HEAD
```

Include in every agent review prompt: `"Review the state at SHA: [sha]"`

---

## Reviewer Selection

When requesting human review, match the reviewer to the concern:

| Concern | Who to ask |
|---------|-----------|
| Correctness / logic | Author of the code being changed, or domain expert |
| Architecture / design | Most experienced person on the team |
| Test coverage | Anyone who has worked on testing infrastructure |
| Performance | Anyone with profiling or benchmarking experience |

Do not add reviewers as a formality. Each reviewer MUST have a specific reason for being on the list.

---

## Responding to "LGTM"

If a reviewer approves without commenting on the specific concerns you listed:

- Ask explicitly: "Did you have a chance to look at [specific concern]? I marked it in the review focus section."
- Do not accept a blanket LGTM as coverage of your stated concerns. It means the reviewer had no issues — it does not mean they checked what you asked them to check.

---

## Red Flags — STOP

- Opening a pull request before the agent pre-review is complete and all BLOCKERs resolved
- Requesting review without a description of what changed and what to focus on
- Requesting review while CI is still running or red
- Requesting review on a draft pull request
- Failing to link the pull request to the issue it resolves

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "The PR description explains everything — reviewers will figure it out" | Reviewers read a lot of PRs. A focused review request is faster and produces better feedback. |
| "I'll just ask for a quick look" | "Quick look" reviews find nothing. State what you want reviewed. |
| "CI is red but it's a flaky test" | Red CI is red CI. Fix or document the flake; do not request review against it. |
| "I'll address the agent findings after human review" | Agent BLOCKERs must be resolved first. Human review should not be spent on issues a machine already found. |
| "I reviewed the diff myself, that's equivalent" | Self-review does not catch the issues a fresh reviewer catches. Dispatch anyway. |
