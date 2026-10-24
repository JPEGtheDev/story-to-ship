---
title: "Three-Role Loop Reference"
description: "The three-role loop for a code todo that adds or changes behaviour: when it applies, dispatch order, the role rules for test-writer, pass-maker and refactorer, the test-path predicate, the role-boundary detector, what the detector does not catch, and failure routing."
domain: skills
subdomain: subagent-driven-development
tags: [skills, subagent-driven-development, references, three-role, test-driven-development]
related:
  - "../SKILL.md"
  - "SDD_LOOP.md"
---

# Three-Role Loop

## 1. Purpose and when the loop applies

The three-role loop splits one code todo into three dispatches, each run by a different implementer. The test-writer writes the failing test, the pass-maker writes the code that passes it, and the refactorer cleans up. No single agent writes both the test and the code it is judged against.

Every plan entry carries one marker line, `loop: three-role` or `loop: single`, with a one-line reason. The rule for choosing is in the loop-marker section of the writing-plans skill's todo templates.

- `loop: three-role` when the todo adds or changes behaviour in a non-prose source file of a repo with a runnable test suite.
- `loop: single` for prose, config, a repo with no runnable suite, a pure refactor or deletion, fix rounds after the end review, and reconcile fix rounds.
- A todo that mixes code and prose is split into a code todo and a prose todo before dispatch.

## 2. Dispatch order

1. Optional stub commit (see below).
2. test-writer dispatch: one commit, `test(scope): ...`.
3. pass-maker dispatch: one commit, `feat(scope): ...` or `fix(scope): ...`.
4. refactorer dispatch: one commit, `refactor(scope): ...`, or no commit.
5. One spec review over the commits.

The optional stub commit comes before step 2. Type or signature stubs, and build-registration files that RED needs in order to fail at run time rather than at compile time, are committed by a pass-maker-role implementer before the test is written. The stub commit is checked as pass-maker. It is a dispatch of its own, so the test-writer still starts from the stub commit.

Rules that hold for the whole sequence:

- One commit per role. The detector takes the base as the commit's parent, so a dispatch that makes two commits cannot be checked as one role.
- Each role is a fresh child in its own worktree, based on the previous role's commit. The dispatcher never reuses or resumes a role child.

## 3. Role rules

### test-writer

- Writes one failing test against the seam named in the plan's seam table.
- Changes test files only. Test helpers and fixtures under test paths count as test files. A change to any other file is a finding, and the todo returns for a fresh test-writer.
- Runs the test. The failure must be a run-time assertion failure, not a compile or import error. A compile or import error is not a valid RED.
- Commits `test(scope): ...` with the failure output pasted in the reply.
- If the test passes at once, return BLOCKED: the behaviour already exists or the test is wrong. The todo goes back to planning.

### pass-maker

- A different implementer from the test-writer.
- Changes non-test files only.
- Writes the least code it can justify. It never hardcodes the expected value.
- Editing, deleting or skipping a test is a finding.
- Runs the full suite and pastes the run.
- Commits `feat(scope): ...` or `fix(scope): ...`.
- If the test is wrong or a case is missing, return BLOCKED to the coordinator. The coordinator opens a new todo with its own test-writer. The pass-maker never writes the test.

### refactorer

- A different implementer from the test-writer and the pass-maker.
- Improves names, function size, duplication and dependency direction.
- May edit a test for readability only.
- Keeps the suite green and pastes the run.
- Commits `refactor(scope): ...`, or reports `no refactor needed: <reason>` and commits nothing.
- A behaviour change is a finding.
- If the suite turns red, the refactorer reverts its changes before reporting.

## 4. Test-path predicate

The default test-path predicate is the extended regular expression (ERE) in the detector script in section 5, matched case-insensitively. The plan's `Test paths:` line may override it with one ERE, which the dispatcher passes to the detector as its third argument unchanged.

## 5. Boundary detector

Run the detector as `sh <script> <role> <commit> [test-path ERE]`:

- `role` is `test-writer`, `pass-maker` or `refactorer`.
- `commit` is one role commit. Its parent is the base for the diff.
- The script reads the repository from its current directory, so run it from inside the feature worktree that holds the commit. The `git -C` form does not apply to it.
- Exit codes: 0 means the boundary held and prints `OK <role>`. 1 means a violation and prints one `VIOLATION` line per finding. 2 means bad input (unknown role or unknown commit).

Save the script below to a file and run it as shown. The block is built from the script file, not retyped.

```sh
#!/bin/sh
# usage: role-check.sh <role> <commit> [test-path-ERE]
# role: test-writer | pass-maker | refactorer. The commit is one role commit; its parent is the base.
# Exit 0 = boundary held, 1 = violation, 2 = bad input. Needs git and a POSIX grep.
role=$1; commit=$2
test_re=${3:-'(^|/)(tests?|__tests__|spec|testdata|fixtures)/|(^|/)test_[^/]*$|(^|/)conftest\.py$|_(test|spec)\.[^/]*$|(Tests?|Spec)\.[^/]*$|\.(spec|test)\.[^/]*$'}
case $role in test-writer | pass-maker | refactorer) ;; *) echo "unknown role: $role" >&2; exit 2 ;; esac
base="$commit^"
git rev-parse --verify -q "$commit" >/dev/null || { echo "bad commit: $commit" >&2; exit 2; }
status=$(git -c core.quotePath=false diff --name-status "$base" "$commit") || exit 2
bad=0
if [ -z "$status" ] && [ "$role" != refactorer ]; then echo "VIOLATION $role commit changes nothing"; bad=1; fi
tab=$(printf '\t')
tests_changed=""
while IFS="$tab" read -r code path rest; do
  [ -n "$code" ] || continue
  for p in "$path" "$rest"; do
    [ -n "$p" ] || continue
    if printf '%s\n' "$p" | grep -Eiq "$test_re"; then is_test=1; else is_test=0; fi
    case $role in
      test-writer) [ "$is_test" = 1 ] || { echo "VIOLATION test-writer touched non-test file: $code $p"; bad=1; } ;;
      pass-maker)  [ "$is_test" = 0 ] || { echo "VIOLATION pass-maker touched test file: $code $p"; bad=1; } ;;
      refactorer)  if [ "$is_test" = 1 ] && [ "$code" != M ]; then echo "VIOLATION refactorer added, deleted or renamed a test file: $code $p"; bad=1; fi ;;
    esac
    if [ "$is_test" = 1 ] && [ "$code" != D ]; then tests_changed="$tests_changed
$p"; fi
  done
done <<LIST
$status
LIST
if [ "$role" != pass-maker ]; then
  # heuristic: added lines in changed test files that disable a test, and (refactorer) net loss of assertions
  skip_re='(^|[^[:alnum:]_])(skip|xit|xtest|xfail|pending|todo)([^[:alnum:]_]|$)|@Ignore|#\[ignore\]|t\.Skip|DISABLED_|expectedFailure|\.only\('
  assert_re='assert|expect|EXPECT_|ASSERT_|CHECK'
  added=0; removed=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    d=$(git -c core.quotePath=false diff "$base" "$commit" -- "$f")
    hit=$(printf '%s\n' "$d" | grep -E '^\+' | grep -vE '^\+\+\+' | grep -Ei "$skip_re" || true)
    if [ -n "$hit" ]; then echo "VIOLATION $role added a skip marker in $f: $hit"; bad=1; fi
    a=$(printf '%s\n' "$d" | grep -E '^\+' | grep -vE '^\+\+\+' | grep -Eic "$assert_re" || true)
    r=$(printf '%s\n' "$d" | grep -E '^-' | grep -vE '^---' | grep -Eic "$assert_re" || true)
    added=$((added + a)); removed=$((removed + r))
  done <<FILES
$tests_changed
FILES
  if [ "$role" = refactorer ] && [ "$removed" -gt "$added" ]; then echo "VIOLATION refactorer removed $removed assertion lines and added $added"; bad=1; fi
fi
[ "$bad" = 0 ] && echo "OK $role"
exit "$bad"
```

## 6. What the detector does not catch

The detector checks which paths each role changed and a few text heuristics. It does not judge the items below. For each of these, the reviewer runs the command again and reads the diff to judge it.

- three different implementers
- the commit type
- the pasted RED and GREEN output
- RED is a run-time assertion failure, not a compile error
- least code (for example hardcoding the expected value)
- a refactor that changes behaviour
- weakened assertions inside a modified test
- test helpers outside the test-path predicate
- skip markers beyond the heuristic list
- whether the seam in the plan is the one the test targets

A pinned CI line proves that this wording exists in the file. It does not prove that anyone follows it.

## 7. Failure routing

- A role boundary finding (a `VIOLATION` line, exit 1) means one fresh dispatch of the same role, based on the commit that the role's first dispatch started from.
- A second finding for the same role in the same todo means the cap reached for that todo. The open findings are stated to the owner.
- Each fresh dispatch prompt is a file. Before the prompt is sent, the dispatcher runs every check the prompt asks the role to run on a must-pass input and on a must-fail input, and pastes both outputs. The prompt carries that paired pass/fail run for each check.
