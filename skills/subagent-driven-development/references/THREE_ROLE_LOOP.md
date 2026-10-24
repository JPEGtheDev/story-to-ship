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
3. pass-maker dispatch: one commit, `feat(scope): ...` or `fix(scope): ...`, that makes the failing test pass, the passing step (GREEN).
4. refactorer dispatch: one commit, `refactor(scope): ...`, or no commit.
5. One spec review over the commits.

The optional stub commit comes before step 2. Type or signature stubs, and build-registration files that the failing-test step (RED) needs in order to fail at run time rather than at compile time, are committed by a pass-maker-role implementer before the test is written. A stub commit holds type or signature stubs and build-registration files only, no behaviour, and the suite stays green (or at least still builds) after it. The stub commit is checked as pass-maker. It is a dispatch of its own, so the test-writer still starts from the stub commit. The stub commit type is `chore(scope): ...`, and the dispatch task must say it is a stub commit.

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
- If the test is wrong or a case is missing, return BLOCKED to the coordinator. The coordinator opens a new todo with its own test-writer. The pass-maker never writes the test. The new todo's first dispatch is a test-writer dispatch whose one commit reverts the earlier failing-test commit; the detector checks that commit as test-writer. The new failing test is a second, separate test-writer dispatch based on that revert commit. A todo never ends on a failing suite.

### refactorer

- A different implementer from the test-writer and the pass-maker.
- Improves names, function size, duplication and dependency direction.
- The refactorer never adds, deletes or renames a test file; it may edit an existing test for readability only.
- Keeps the suite green and pastes the run.
- Commits `refactor(scope): ...`, or reports `no refactor needed: <reason>` and commits nothing.
- A behaviour change is a finding.
- If the suite turns red, the refactorer reverts its changes before reporting.

## 4. Test-path predicate

The plan's `Test paths:` line reads `default` or gives one extended regular expression (ERE). When it reads `default`, the dispatcher omits the third argument; the script also accepts the word `default` as the third argument and treats it as no override. When the line gives an ERE, the dispatcher passes it to the detector as its third argument unchanged, and the script matches it case-insensitively.

The default predicate is the one in the detector script in section 5. It matches directory names (tests, test, __tests__, spec, testdata, fixtures), test_ prefixes, _test and _spec suffixes, .test and .spec infixes, conftest.py, and the CamelCase suffixes Test, Tests and Spec after a lower-case letter or digit (FooTest.java matches, latest.c does not). Matching ignores case for the directory, prefix, suffix and infix parts; the CamelCase suffix part is case-sensitive. Matching is by name, so a source file that is named like a test is misread as a test; the plan's override is the fix.

## 5. Boundary detector

Run the detector as `sh <script> <role> <commit> [test-path ERE]`:

- `role` is `test-writer`, `pass-maker` or `refactorer`.
- `commit` is one role commit. Its parent is the base for the diff.
- The script reads the repository from its current directory, so run it from inside the feature worktree that holds the commit. The `git -C` form does not apply to it. The coordinator runs it in a subshell, `(cd <feature worktree> && sh <script> <role> <commit>)`, so no directory change outlives the call; this is the one allowed cd.
- Exit codes: 0 means the boundary held and prints `OK <role>`. 1 means a violation and prints one `VIOLATION` line per finding. 2 means an input the script cannot judge: an unknown role, an unknown or bad commit, a root commit, a merge commit, a test-path pattern that is not a valid extended regular expression, or a path that git must C-quote (a tab, double quote or backslash in the name). The reviewer checks those by hand with `git diff --name-status`.
- The dispatcher also confirms that each role made one commit with `git rev-list --count <previous role commit>..<role head>`, which must print 1, except 0 for a refactorer that reports `no refactor needed`. Any other number is a boundary finding. When a refactorer commits nothing there is no commit to check: the detector is skipped, the count must print 0, and the dispatcher reads `git status` of the refactorer worktree. The previous role commit is, for the first role, the stub commit when one exists, otherwise the commit the todo started from; for each later role it is the commit of the role dispatched before it.

Save the script below to a file and run it as shown. The block is the script file byte for byte, not retyped.

```sh
#!/bin/sh
# usage: role-check.sh <role> <commit> [test-path ERE]
# role: test-writer | pass-maker | refactorer. The commit is one role commit; its parent is the base.
# Exit 0 = boundary held, 1 = violation, 2 = input this script cannot judge (check by hand).
# Needs git and a POSIX grep. The test-path ERE argument is optional; "default" means omitted.
role=$1; commit=$2; test_re=$3
[ "$test_re" = default ] && test_re=
if [ -n "$test_re" ]; then printf 'x\n' | grep -Eiq -e "$test_re"; [ $? -le 1 ] || { echo "bad test-path pattern: $test_re" >&2; exit 2; }; fi
dir_re='(^|/)(tests?|__tests__|spec|testdata|fixtures)/|(^|/)test_[^/]*$|(^|/)conftest\.py$|_(test|spec)\.[^/]*$|\.(spec|test)\.[^/]*$'
camel_re='[a-z0-9](Test|Tests|Spec)\.[^/]*$'
case $role in test-writer | pass-maker | refactorer) ;; *) echo "unknown role: $role" >&2; exit 2 ;; esac
git rev-parse --verify -q "$commit^{commit}" >/dev/null || { echo "bad commit: $commit" >&2; exit 2; }
git rev-parse --verify -q "$commit^" >/dev/null || { echo "root commit has no parent to compare with" >&2; exit 2; }
if git rev-parse --verify -q "$commit^2" >/dev/null; then echo "merge commit: check by hand" >&2; exit 2; fi
base="$commit^"
status=$(git -c core.quotePath=false diff --no-color --no-ext-diff --name-status "$base" "$commit") || exit 2
if printf '%s\n' "$status" | grep -Eq "$(printf '\t')\""; then echo "a path needs C-quoting (tab, quote or backslash): check by hand" >&2; exit 2; fi
is_test() {
  if [ -n "$test_re" ]; then printf '%s\n' "$1" | grep -Eiq -e "$test_re"; return; fi
  printf '%s\n' "$1" | grep -Eiq "$dir_re" || printf '%s\n' "$1" | grep -Eq "$camel_re"
}
bad=0
if [ -z "$status" ] && [ "$role" != refactorer ]; then echo "VIOLATION $role commit changes nothing"; bad=1; fi
tab=$(printf '\t')
tests_changed=""
while IFS="$tab" read -r code path rest; do
  [ -n "$code" ] || continue
  for p in "$path" "$rest"; do
    [ -n "$p" ] || continue
    if is_test "$p"; then t=1; else t=0; fi
    case $role in
      test-writer) [ "$t" = 1 ] || { echo "VIOLATION test-writer touched non-test file: $code $p"; bad=1; } ;;
      pass-maker)  [ "$t" = 0 ] || { echo "VIOLATION pass-maker touched test file: $code $p"; bad=1; } ;;
      refactorer)  if [ "$t" = 1 ] && [ "$code" != M ]; then echo "VIOLATION refactorer added, deleted or renamed a test file: $code $p"; bad=1; fi ;;
    esac
    if [ "$t" = 1 ] && [ "$code" != D ]; then tests_changed="$tests_changed
$p"; fi
  done
done <<LIST
$status
LIST
if [ "$role" != pass-maker ]; then
  # heuristic: added lines in changed test files that disable a test, and (refactorer) net loss of assertions
  skip_re='(^|[^[:alnum:]_])(it|test|describe)\.(skip|only|todo)\(|(^|[^[:alnum:]_])(xit|xtest|xdescribe)\(|(^|[^[:alnum:]_])(pytest\.)?skip\(|@pytest\.mark\.(skip|xfail)|@(Ignore|Disabled)|#\[ignore\]|t\.Skip(Now)?\(|DISABLED_|expectedFailure|\.only\('
  assert_re='assert|expect|EXPECT_|ASSERT_|CHECK'
  added=0; removed=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    d=$(git -c core.quotePath=false diff --no-color --no-ext-diff "$base" "$commit" -- "$f")
    hit=$(printf '%s\n' "$d" | grep -E '^\+' | grep -vE '^\+\+\+' | grep -E "$skip_re" || true)
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
- whether a stub commit holds no behaviour
- the pasted RED and GREEN output
- RED is a run-time assertion failure, not a compile error
- least code (for example hardcoding the expected value)
- a refactor that changes behaviour
- weakened assertions inside a modified test
- test helpers outside the test-path predicate
- skip markers beyond the heuristic list
- whether the seam in the plan is the one the test targets
- a mistyped test-path pattern that is valid regex and matches the wrong files

The text heuristics have known limits. The skip scan lists annotation and call forms only (it.skip, pytest.skip, xit, @Ignore, #[ignore], t.Skip, DISABLED_ and similar), not every spelling. The refactorer assertion count compares lines that mention assert, expect or check, so pulling repeated assertions into a helper can be flagged. Known false positives of the skip scan are a parser call such as `p.skip(1)`, which matches the skip pattern, and a renamed test file that already held a skip marker, which is reported. A violation that a reviewer judges a false positive of a heuristic does not count toward the cap in section 7; the reviewer records why.

A build that lists tests explicitly in a manifest outside the test paths (for example a root build file, a Cargo test table, a project file) leaves no role that may register a new test file; the plan's `Test paths:` line must then name that manifest, so the test-writer may change it, and a pass-maker stub cannot register a test that does not exist yet. A manifest shared by tests and sources (a root build file, a dependency list) cannot be handed to one role, because the override that lets the test-writer change it makes it a test file for the pass-maker; a pass-maker commit that must change such a manifest is checked by hand like an exit-2 input and the plan entry records that.

A pinned CI line proves that this wording exists in the file. It does not prove that anyone follows it.

## 7. Failure routing

- A role boundary finding (a `VIOLATION` line, exit 1) means one fresh dispatch of the same role, based on the commit that the role's first dispatch started from.
- A second finding for the same role in the same todo means the cap is reached for that todo. The open findings are stated to the owner.
- Each fresh dispatch prompt is a file. Before the prompt is sent, the dispatcher runs every check the prompt asks the role to run on a must-pass input and on a must-fail input, and pastes both outputs. For a check that runs the suite, the must-pass input is the commit with the code, and the must-fail input is the commit before it, which holds the test alone. The prompt carries that paired pass/fail run for each check.
- When the single spec review over the three commits fails, the finding goes to a fresh implementer of the role whose commit holds the finding, as one new commit. The detector runs again on that commit. This is a fix round of the todo. A test-writer fix commit leaves the suite red, so it is always followed by a pass-maker dispatch (fresh, one commit, detector run) so the todo does not end red.
