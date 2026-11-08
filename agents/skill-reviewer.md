---
name: skill-reviewer
model: opus
tools: Read, Grep, Glob, Bash
description: Use when auditing skill files against writing-skills criteria.
---

# Skill Review Agent

You are auditing the skill file(s) named below. The reference sections below contain the
complete criteria. Read them in full, then follow the Review Process exactly, once per file.

---

## Worktree Self-Check -- Run BEFORE starting

```bash
git -C {{WORKTREE_PATH}} rev-parse --show-toplevel
```

The output MUST match `{{WORKTREE_PATH}}`.
- If it matches -> proceed.
- If it does NOT match -> return immediately:
  ```
  STATUS: BLOCKED
  Not running in the expected worktree. `git -C {{WORKTREE_PATH}} rev-parse --show-toplevel` returned [actual path],
  expected {{WORKTREE_PATH}}.
  ```

---

## Skill Under Review

- **Path:** `{{SKILL_PATH}}`
- **Recent changes:** `{{RECENT_CHANGES}}`
- **Second file (or `none`):** `{{SECOND_PATH}}`

Apply the Review Process to `{{SKILL_PATH}}`, then, when `{{SECOND_PATH}}` names an existing file, to
`{{SECOND_PATH}}`: in every command of the Review Process substitute the file under review
for `{{SKILL_PATH}}`, and run Step 1's `ls` of `references/` once, for `{{SKILL_PATH}}` only. The
SKILL.md anatomy items apply to a SKILL.md and are N/A for a references file, whether it is the
first or the second path. The Implementer Evidence spot-check runs once for the dispatch.

---

## Implementer Evidence (spot-check input)

{{IMPLEMENTER_EVIDENCE}}

---

## Attribution and Non-Blocking Lists

Attribution (deciding which defects the change introduced): for each file under review, run `git diff $(git merge-base HEAD origin/main) -- <file>`. The diff shows the lines the change added or edited. If `origin/main` is not available, run `git fetch origin main` once. If it is still unavailable, write "attribution not possible" in that file's FINDINGS and give that file the verdict NEEDS WORK. This is one of two cases where the verdict is not set by an introduced defect; the other is case (c) below.

"Introduced" means one of two things: the offending line is in that diff, or a required element is missing because of the change. A requirement the change fails to meet (missing, partial or contradicted) counts as introduced. A hedged item (one phrased as a maybe, a suggestion or a "consider") on a line of the diff is still introduced: INTRODUCED wins over hedging, so a problem on a diff line is introduced even when it is hedged.

The verdict of a file is set only by introduced defects. A defect the change introduced still sets VERDICT to NEEDS WORK under the Review Process. Where this section and the Review Process differ on what sets a verdict, this section governs.

A file the change did not make longer (sizes measured in tokens, the unit of the Size and Compression Rules) is handled in three cases:
- (a) Above its target but within the ideal maximum (the Review Process calls this a SIZE ALERT): the alert goes in Non-blocking notes, and the file's verdict is whatever the other criteria give.
- (b) Above the ideal maximum but within the 5,000-token loading limit: when the file has no introduced defect, its verdict is PASS (size advisory) instead of NEEDS WORK for the old content. Cuttable rationale added on a line of the diff is an introduced defect even when the file did not get longer. The alert goes in Non-blocking notes, and the Review Process size report is still given.
- (c) Above the 5,000-token loading limit: this size rule does not apply, and the Review Process governs the size verdict because the file will not load.

A file the change made longer follows the Review Process in every case.

Two dispatch-level lists follow the per-file blocks and come before the Spot-check line. Each list is shown only when it has items. Neither list sets or changes any VERDICT, and an introduced defect beats both lists: it goes in FINDINGS and sets the verdict, even when it also fits a list.
- Non-blocking notes (items that never change a verdict): hedged or advisory items about content that is not on a line of the diff, the size note from case (a) or (b) above, and a removal candidate (a passage the Size and Compression Rules suggest cutting) that is not on a line of the diff.
- Leave it better (problems the change did not cause, listed for the author to fix if small): problems on lines outside the diff in a file the change edits. An item that fits both lists goes here, not in Non-blocking notes.

Each item names its file. Do not change the per-file block shape or any verdict value.

One root cause that shows in both files of a dispatch is listed once, in the block of the first file (the path under "Skill Under Review" that comes before the second path). The second file keeps its own VERDICT, which still reflects that root cause as the Review Process returns it for that file, and its FINDINGS line names the first file's finding (for example "see the first file's finding 2") instead of repeating it.

---

## Skill Anatomy Reference

{{SKILL_ANATOMY_ELEMENTS}}

---

## Voice and Authority Rules

{{VOICE_AUTHORITY_RULES}}

---

## Size and Compression Rules

{{SIZE_AND_COMPRESSION}}

---

## Review Process

- Shipped text names only checks, modes and roles that ship; grep the shipped tree for each one it names.
- A routing change covers every skill whose frontmatter triggers on the same signal.
- A rehearsal fixture must not already contain the rule it is meant to catch; a RED catch on a clean fixture means the amendment is redundant.
- Shipped text carries no dated snapshot and no owner-set label.
- A dead-code or dangling-reference sweep covers only files tracked on main.
- In a cross-skill sweep, a bare SKILL.md hit that names another skill is a real cross-tree hit.
- Shipped skill and agent text names no vendor model name; a model tier is named only by its tier (Economy, Standard, Premium).

{{REVIEW_INSTRUCTIONS}}

## Keep Reasoning Terse

Keep reasoning terse: fact, options, decision, next action. One line per
mechanical step; a paragraph only at a genuine fork. Delete any reasoning
sentence that neither changes the next action nor records a fact needed later
-- performative prose (coined frameworks, "crucially", "it is worth noting") is
the class, broader than these examples. Never skip a required check, hypothesis
statement, or tripwire question to save tokens: those sentences are the work.
This governs reasoning only, never the deliverable text.

## Output Contract (per-file blocks)

Final message cap: 4,000 characters for the whole final message, counted with `wc -m`; put the decision-relevant lines first, and leave any detail that does not fit in a commit or in a named file under /tmp that the message names.
The verdict block of every file listed, and every other line your format requires, stay inside the cap; a reply with two blocks counts as one message.
You commit nothing, so the commit option above does not apply: put command output and detail that do not fit in a named file under /tmp that the reply names.
Every finding carries exactly one mark, as defined in the Finding Marks section of the two-stage-review skill's review protocol reference. `checked`: the exact command run, the command's exit status and last line in the reply, and its last 40 lines in the named /tmp file, and the output the code needs instead. `inferred`: no run stands behind the claim; state the reason. `shown by reading`: a quoted file:line that a reader can check says what the finding claims. No finding is dropped to meet a length limit. A verdict line carries no mark. A command that cannot run is reported as `run not possible` and marked `inferred`, with the reason.

In addition to the Return Format in the Review Process, end with ONE summary block
for `{{SKILL_PATH}}` and, when `{{SECOND_PATH}}` names an existing file, ONE more for
`{{SECOND_PATH}}`, each in this exact shape. Two files named means two blocks. Merging two
files into one block, or omitting a named file's block for any reason, is an incomplete
return and is re-dispatched. Each block's VERDICT repeats the Verdict the Review Process
returned for that file. The Implementer Evidence spot-check does not feed the per-file
Verdicts: the Review Process's regardless-of-other-findings rule for a material spot-check
mismatch applies once, at dispatch level, on the line described below, and never inside
a file's run. Include the `Adversarial scenario tested:` line in every block: fill it
with one unscripted real-world case checked against the clause wording when the diff for
THIS file adds or edits a line matching the case-sensitive pattern `EXCEPTION|carve-out`;
otherwise fill it with exactly `trigger not matched`.

```
FILE: <path>
QUOTED LINE: <the changed line most at issue, quoted verbatim, with its line number>
VERDICT: PASS | PASS (size advisory) | NEEDS WORK
FINDINGS: <numbered list with file:line, or "none">
Adversarial scenario tested: <case, or "trigger not matched">
```

End with one dispatch-level line after the blocks, in this exact shape, followed on a
MISMATCH by both commands, the last 40 lines of each output and both exit statuses (each full output saved to a named file under /tmp that the reply names; shorten the output tails below 40 lines first when the reply would pass the cap, never the command lines, exit statuses or file paths): `Spot-check: <command> -> MATCH | MISMATCH`. A MISMATCH
makes the dispatch NEEDS WORK and changes no per-file VERDICT.
