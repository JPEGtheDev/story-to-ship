---
name: finishing-a-development-branch
license: MIT
description: Use when a development branch is complete and ready to merge.
---


## Iron Law

```
YOU MUST COMPLETE ALL FIVE STEPS BEFORE CONSIDERING A BRANCH CLOSED.
No exceptions.
```

Violating the letter of this rule is violating the spirit of this rule.

**Announce at start:** "I am using the finishing-a-development-branch skill to close out [branch name]."

---

## BEFORE PROCEEDING

Before beginning the branch ceremony:

1. All acceptance criteria from the original task are addressed (DONE or tracked in a new issue)
2. The host project's build command (as its docs define it) exits 0 - no build errors
3. The host project's test suite exits 0 - all tests pass
4. Every commit on the branch uses conventional commit format
5. No debug-only, Work In Progress (WIP), or dead code remains in the diff

[+] All met -> proceed through Steps 1-5
[-] Any unmet -> resolve the unmet item before starting the branch ceremony

---

## Step 1: Verification Gate

Before opening a PR or squashing commits, run the full verification sequence:

1. Run the host project's build command (as its docs define it) -- must succeed
2. Run the host project's test suite -- all tests green
3. Run the host project's formatter -- format clean
4. `git diff` -- verify no unintended changes from formatting

[+] All four pass -> proceed to Step 2
[-] Any fail -> fix before proceeding; do not open a PR against a red branch

See `verification-before-completion` skill for the complete gate.

---

## Step 2: Branch Audit

Before writing the PR, answer:

1. **Every acceptance criterion from the original task -- is it delivered?**
   List each criterion. Mark DONE or OPEN. Any OPEN item must be extracted to a new issue or be deliberately deferred (with the user's knowledge).

2. **Are there any open TODOs in the code?**
   Run: `grep -rn "TODO\|FIXME\|HACK\|XXX" src/ tests/`
   Each hit must be either fixed now, converted to an issue, or accepted with a comment explaining why.

3. **Does the diff contain any accidental changes?**
   Run: `git diff main...HEAD`
   Review every file. Anything that doesn't belong on this branch must be reverted or moved to a separate branch.

4. **Is there dead code?**
   Unused functions, commented-out blocks, or prototype code left over from exploration must be removed.

5. **Has a pre-PR hygiene sweep been run over every changed tracked file?**
   Before opening or updating any PR, run a repo-wide sweep over every file changed on the branch:
   ```
   for f in $(git diff --name-only main...HEAD); do
     [ -f "$f" ] || continue
     grep -nE '[A-Z][0-9]{1,2}' "$f"      # campaign/planning labels (letter+digit tags, e.g. FS3, T11c, A14, R2, Q2)
     grep -nE '#[0-9]+' "$f"              # issue-number tags
     grep -nP '[^\x00-\x7F]' "$f"         # non-ASCII characters
     grep -nE '(\.\./\.\./skills/|skills/[A-Za-z0-9_-]+/references/)' "$f"   # cross-tree file references in non-machine contexts
     grep -nE '\b[A-Z][A-Z0-9_]{2,}\.md\b' "$f"   # bare doc-file names -- real only when the scanning file is a skill or agent-template file AND the named file lives in a different skill tree
   done
   ```
   Also read every changed file for repo-internal jargon a reader with no project context could not resolve from the file alone, and for unexpanded acronyms on first use -- neither has a reliable grep pattern.
   A real hit -- a campaign or planning label, an issue-number tag, repo-internal jargon, an unexpanded acronym, a cross-tree file reference (a slash path, or a bare doc-file name cited by a skill or agent-template file, naming a file in a different skill tree), or a non-ASCII character -- is fixed before the PR goes up, no exceptions. Only a detector false positive -- a regex match that is not actually one of the defect classes above -- may instead be adjudicated in the PR body, named hit-by-hit. Bare doc-file name matches are the sole class exempt from hit-by-hit naming: adjudicate them as one class, stating the hit count and that either every hit names a file outside any other skill tree, or the citing file is outside skills/ and agents/, where the `writing-skills` skill's Cross-Skill Reference Rule does not bind. A hit found later -- after the PR is opened -- is a gate failure, not an adjudication candidate.

---

## Step 3: Commit Cleanup

Choose one of these four options -- do not mix them:

| Option | When to use |
|--------|-------------|
| **Squash into one commit** | Small feature/fix -- all changes tell one story |
| **Squash into logical groups** | Larger branch -- separate "feat" from "test" from "refactor" commits |
| **Keep all commits** | Each commit is already clean, atomic, and independently meaningful |
| **Interactive rebase** | Mix of clean and messy commits -- clean up before squashing |

**Squash prescribed command:** Use `git reset --mixed HEAD~N`. Use `--mixed`, not `--soft`. `--soft` carries staged hunks forward and can silently include unintended changes. `--mixed` clears the index so the new commit starts from a clean slate.

After reset:
1. Run `git status` -- confirm working tree is unchanged, index is empty.
2. Re-stage and commit with your squash message.
3. Run `git show --stat HEAD` -- verify the squash commit contains exactly the files you intended and nothing else.

**Every resulting commit must:**
- Build and pass tests on its own
- Use conventional commit format: `<type>[scope]: <description>`
- Have a body that answers "what changed and why" (not just "what")

See `versioning` skill for conventional commit rules.

---

## Step 4: PR Creation

**Title:** Must be a valid conventional commit message -- this becomes the squash commit on merge.

**Description must include:**
```
## What changed
[1-3 sentences: the change and its purpose]

## Why
[The problem this solves or the requirement it fulfills]

## Acceptance criteria
- [ ] [criterion 1]
- [ ] [criterion 2]

## Test plan
[How to verify this change works]

## Design decisions (if applicable)
[Paste the Design Decision Record from brainstorming, if one exists]
```

**Do NOT:**
- Open a PR against a failing CI
- Open a PR with "WIP" in the title unless explicitly flagging for early review
- Leave the PR description blank

---

## Step 5: After Merge

1. **Delete the branch** -- merged branches are dead weight
2. **Update linked issues** -- close any issues that were resolved
3. **Verify the merge commit built green** on main -- do not assume
4. **Remove any worktrees** created for this branch: `git worktree list` and prune

**Squash-merge note:** After a squash merge, `git branch --merged main` will NOT list the feature branch -- the squash creates a new commit that does not retain the branch tip as an ancestor, so the ancestry-based check reports a false negative. Do NOT conclude the branch is unmerged from that signal. Confirm merge by TREE-equality instead: `git diff <feature-branch> <squash-merge-commit>` returns empty when the branch content is fully on main. Then delete: `git branch -d <feature-branch>` succeeds only while the branch's local remote-tracking ref still exists; once that stale ref is pruned (e.g. `git fetch --prune`, which surfaces a host's auto-delete-on-merge on your next fetch), `-d` fails with "not fully merged" -- use `git branch -D <feature-branch>` after tree-equality has confirmed the content is on main.

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I'll clean up the commits later" | Later never comes. Clean them now while context is fresh. |
| "The tests pass locally, CI will be fine" | CI has a different environment. It fails independently. Verify the diff, not the confidence. |
| "It's close enough -- I'll fix it in follow-up" | Undefined follow-up is a polite word for "never." Open a tracking issue with a due date or do it now. |
| "The PR description can be filled in later" | PR descriptions written after the fact are summaries, not design records. Write them now. |
| "CI passed on the branch, merge is safe" | CI on the branch does not verify the merge commit. Verify CI is green on main AFTER the merge. |
| "Reviewers will just read the diff -- the PR description is optional" | Reality: YOU MUST write the PR description before opening the PR. The diff shows what changed; the description explains why. |
| "The sweep hit is in a fixture or test input, so it doesn't count" | Fixture and test input files are tracked shipped files like any other file on the branch. A label or jargon hit inside a fixture is a real hit -- fix it, no exceptions; the PR body may adjudicate a sweep match only when it is a detector false positive, not actually one of the defect classes. No exemption for fixture or test-input scenarios. |

---

## Red Flags -- STOP

- Opening a PR with failing tests
- Squashing commits without reading the resulting diff
- Merging without checking CI on main after merge
- Closing a branch with OPEN acceptance criteria and no tracking issue
- Pushing to open a PR without reading the full diff (`git diff main...HEAD`) line by line
- "I'll skip the post-merge cleanup -- branches and worktrees can wait" -- **STOP. Delete the branch, close linked issues, and prune worktrees immediately after merging.**
