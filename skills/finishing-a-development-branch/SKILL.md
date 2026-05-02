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

## Step 1: Verification Gate

Before opening a PR or squashing commits, run the full verification sequence:

```bash
cmake --build build
./build/tests/ParticleViewerTests
find src tests -name "*.cpp" -o -name "*.hpp" | xargs clang-format -i
git diff  # verify no unintended changes from formatting
```

✓ All four pass → proceed to Step 2
✗ Any fail → fix before proceeding; do not open a PR against a red branch

See `verification-before-completion` skill for the complete gate.

---

## Step 2: Branch Audit

Before writing the PR, answer:

1. **Every acceptance criterion from the original task — is it delivered?**
   List each criterion. Mark DONE or OPEN. Any OPEN item must be extracted to a new issue or be deliberately deferred (with the user's knowledge).

2. **Are there any open TODOs in the code?**
   Run: `grep -rn "TODO\|FIXME\|HACK\|XXX" src/ tests/`
   Each hit must be either fixed now, converted to an issue, or accepted with a comment explaining why.

3. **Does the diff contain any accidental changes?**
   Run: `git diff main...HEAD`
   Review every file. Anything that doesn't belong on this branch must be reverted or moved to a separate branch.

4. **Is there dead code?**
   Unused functions, commented-out blocks, or prototype code left over from exploration must be removed.

---

## Step 3: Commit Cleanup

Choose one of these four options — do not mix them:

| Option | When to use |
|--------|-------------|
| **Squash into one commit** | Small feature/fix — all changes tell one story |
| **Squash into logical groups** | Larger branch — separate "feat" from "test" from "refactor" commits |
| **Keep all commits** | Each commit is already clean, atomic, and independently meaningful |
| **Interactive rebase** | Mix of clean and messy commits — clean up before squashing |

**Every resulting commit must:**
- Build and pass tests on its own
- Use conventional commit format: `<type>[scope]: <description>`
- Have a body that answers "what changed and why" (not just "what")

See `versioning` skill for conventional commit rules.

---

## Step 4: PR Creation

**Title:** Must be a valid conventional commit message — this becomes the squash commit on merge.

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

1. **Delete the branch** — merged branches are dead weight
2. **Update linked issues** — close any issues that were resolved
3. **Verify the merge commit built green** on main — do not assume
4. **Remove any worktrees** created for this branch: `git worktree list` and prune

---

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "I'll clean up the commits later" | Later never comes. Clean them now while context is fresh. |
| "The tests pass locally, CI will be fine" | CI has a different environment. It fails independently. Verify the diff, not the confidence. |
| "It's close enough — I'll fix it in follow-up" | Undefined follow-up is a polite word for "never." Open a tracking issue with a due date or do it now. |
| "The PR description can be filled in later" | PR descriptions written after the fact are summaries, not design records. Write them now. |
| "CI passed on the branch, merge is safe" | CI on the branch does not verify the merge commit. Verify CI is green on main AFTER the merge. |
| "Reviewers will just read the diff — the PR description is optional" | Reality: YOU MUST write the PR description before opening the PR. The diff shows what changed; the description explains why. |

---

## Red Flags — STOP

- Opening a PR with failing tests
- Squashing commits without reading the resulting diff
- Merging without checking CI on main after merge
- Closing a branch with OPEN acceptance criteria and no tracking issue
- Pushing to open a PR without reading the full diff (`git diff main...HEAD`) line by line
- "I'll skip the post-merge cleanup — branches and worktrees can wait" — **STOP. Delete the branch, close linked issues, and prune worktrees immediately after merging.**
