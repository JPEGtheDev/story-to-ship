#!/bin/sh
# Fixture tests for handback-check.sh: the state, draft, mergeable, head, ci and branch lines, the gh
# failure path, the fetch NOTE line and usage errors. No network: the gh command is a stub that prints
# a JSON fixture file, and the branch fixtures use a local bare repository as origin.
# HANDBACK_CHECK=<path> substitutes another script (used to prove a test can fail).
. "$(dirname "$0")/lib.sh"

SCRIPT=${HANDBACK_CHECK:-$(dirname "$0")/../handback-check.sh}
STUB=$TEST_TMP/gh-stub
REPO=$TEST_TMP/wt
JSON=$TEST_TMP/pr.json
export HANDBACK_GH=$STUB STUB_JSON=$JSON
unset STUB_EXIT

# GOOD_ROLLUP: one successful check run, the all-good rollup.
GOOD_ROLLUP='[{"__typename":"CheckRun","name":"build","status":"COMPLETED","conclusion":"SUCCESS"}]'

# NOTE_LINE: the fetch line printed before the branch line when the default base ref is used.
NOTE_LINE='NOTE fetch: ran git fetch origin main'

write_gh_stub "$STUB" || exit 2

# make_origin_clone <dir> <ahead>: a bare origin at <dir>.origin.git seeded with main, and a clone at
# <dir> on branch agent/s427-t1-tw with <ahead> commits on top of origin/main. Sets FIX_BASE to the
# origin/main sha and FIX_HEAD to the clone HEAD.
make_origin_clone() {
  _seed=$1.seed
  _origin=$1.origin.git
  git init -q -b main "$_seed" || return 1
  printf '%s\n' 'base' > "$_seed/file.txt" || return 1
  git_c "$_seed" add -A || return 1
  git_c "$_seed" commit -q -m base || return 1
  git init -q --bare -b main "$_origin" || return 1
  git_c "$_seed" push -q "$_origin" main || return 1
  git clone -q "$_origin" "$1" || return 1
  git_c "$1" checkout -q -b agent/s427-t1-tw || return 1
  _i=0
  while [ "$_i" -lt "$2" ]; do
    printf '%s\n' "feature $_i" >> "$1/file.txt" || return 1
    git_c "$1" commit -q -a -m "feature $_i" || return 1
    _i=$((_i + 1))
  done
  FIX_BASE=$(git -C "$1" rev-parse origin/main) || return 1
  FIX_HEAD=$(git -C "$1" rev-parse HEAD) || return 1
}

# advance_origin <dir> <count>: push <count> commits to the origin of the clone at <dir>, made from a
# second clone at <dir>.upstream. The clone at <dir> keeps its old origin/main until it fetches.
advance_origin() {
  git clone -q "$1.origin.git" "$1.upstream" || return 1
  _i=0
  while [ "$_i" -lt "$2" ]; do
    printf '%s\n' "upstream $_i" >> "$1.upstream/file.txt" || return 1
    git_c "$1.upstream" commit -q -a -m "upstream $_i" || return 1
    _i=$((_i + 1))
  done
  git_c "$1.upstream" push -q origin main || return 1
}

make_origin_clone "$REPO" 1 || exit 2

# check_pr <state> <isDraft> <mergeable> <headRefOid> [rollup JSON]: write the PR document, then run
# the check with the default arguments. The rollup defaults to GOOD_ROLLUP. Sets RC and leaves stdout
# in $TEST_TMP/out, stderr in $TEST_TMP/err.
check_pr() {
  write_pr_json "$JSON" "$1" "$2" "$3" "$4" "${5:-$GOOD_ROLLUP}"
  sh "$SCRIPT" -n 431 -w "$REPO" -s 427 >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
  RC=$?
}

# assert_case <name> <expected exit> <expected stdout file>: exit, exact stdout, empty stderr.
assert_case() {
  assert_exit "$1 exit" "$2" "$RC"
  assert_file_eq "$1 lines" "$3" "$TEST_TMP/out"
  assert_empty "$1 stderr" "$TEST_TMP/err"
}

# check_ci <name> <expected exit> <rollup JSON> <expected ci line>: the rollup is the only change;
# the other lines stay OK, including the NOTE and branch lines (the shared fixture is 1 ahead, 0 behind).
check_ci() {
  check_pr OPEN false MERGEABLE "$FIX_HEAD" "$3"
  printf '%s\n' "OK state: OPEN" "OK draft: false" "OK mergeable: MERGEABLE" "OK head: $FIX_HEAD" "$4" \
    "$NOTE_LINE" "OK branch: behind 0, ahead 1" > "$TEST_TMP/want-$1"
  assert_case "$1" "$2" "$TEST_TMP/want-$1"
}

# Case 1: all good. Every line is OK and the exit is 0.
check_pr OPEN false MERGEABLE "$FIX_HEAD"
cat > "$TEST_TMP/want-good" <<EOF
OK state: OPEN
OK draft: false
OK mergeable: MERGEABLE
OK head: $FIX_HEAD
OK ci: 1 checks successful
$NOTE_LINE
OK branch: behind 0, ahead 1
EOF
assert_case "all-good" 0 "$TEST_TMP/want-good"

# Case 2: a closed PR fails the state line only.
check_pr CLOSED false MERGEABLE "$FIX_HEAD"
cat > "$TEST_TMP/want-closed" <<EOF
FAIL state: CLOSED
OK draft: false
OK mergeable: MERGEABLE
OK head: $FIX_HEAD
OK ci: 1 checks successful
$NOTE_LINE
OK branch: behind 0, ahead 1
EOF
assert_case "state-closed" 1 "$TEST_TMP/want-closed"

# Case 3: a draft PR fails the draft line only.
check_pr OPEN true MERGEABLE "$FIX_HEAD"
cat > "$TEST_TMP/want-draft" <<EOF
OK state: OPEN
FAIL draft: true
OK mergeable: MERGEABLE
OK head: $FIX_HEAD
OK ci: 1 checks successful
$NOTE_LINE
OK branch: behind 0, ahead 1
EOF
assert_case "draft-true" 1 "$TEST_TMP/want-draft"

# Case 4: mergeable UNKNOWN and CONFLICTING both fail the mergeable line.
check_pr OPEN false UNKNOWN "$FIX_HEAD"
cat > "$TEST_TMP/want-unknown" <<EOF
OK state: OPEN
OK draft: false
FAIL mergeable: UNKNOWN
OK head: $FIX_HEAD
OK ci: 1 checks successful
$NOTE_LINE
OK branch: behind 0, ahead 1
EOF
assert_case "mergeable-unknown" 1 "$TEST_TMP/want-unknown"

check_pr OPEN false CONFLICTING "$FIX_HEAD"
cat > "$TEST_TMP/want-conflicting" <<EOF
OK state: OPEN
OK draft: false
FAIL mergeable: CONFLICTING
OK head: $FIX_HEAD
OK ci: 1 checks successful
$NOTE_LINE
OK branch: behind 0, ahead 1
EOF
assert_case "mergeable-conflicting" 1 "$TEST_TMP/want-conflicting"

# Case 5: a PR head that differs from the worktree HEAD fails the head line with both shas.
check_pr OPEN false MERGEABLE "$FIX_BASE"
cat > "$TEST_TMP/want-head" <<EOF
OK state: OPEN
OK draft: false
OK mergeable: MERGEABLE
FAIL head: pr $FIX_BASE worktree $FIX_HEAD
OK ci: 1 checks successful
$NOTE_LINE
OK branch: behind 0, ahead 1
EOF
assert_case "head-differs" 1 "$TEST_TMP/want-head"

# Case 6a: the gh stub exits non-zero. Exactly one FAIL line per check name, value "gh failed".
# No NOTE line: no fetch runs when gh cannot be read.
export STUB_EXIT=1
check_pr OPEN false MERGEABLE "$FIX_HEAD"
unset STUB_EXIT
cat > "$TEST_TMP/want-ghfail" <<EOF
FAIL state: gh failed
FAIL draft: gh failed
FAIL mergeable: gh failed
FAIL head: gh failed
FAIL ci: gh failed
FAIL branch: gh failed
EOF
assert_case "gh-exit-nonzero" 1 "$TEST_TMP/want-ghfail"

# Case 6b: the gh stub prints invalid JSON. The same six FAIL lines and no crash message.
printf '%s\n' 'not json at all' > "$TEST_TMP/bad.json"
STUB_JSON=$TEST_TMP/bad.json
export STUB_JSON
sh "$SCRIPT" -n 431 -w "$REPO" -s 427 >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
RC=$?
export STUB_JSON=$JSON
assert_case "gh-invalid-json" 1 "$TEST_TMP/want-ghfail"

# Case 7: usage errors exit 2, print a usage message on stderr and nothing on stdout.
# Each run uses the all-good document so a script that ignores the usage error would print OK lines.
write_pr_json "$JSON" OPEN false MERGEABLE "$FIX_HEAD"
for usage in "missing-n|-w $REPO -s 427" "missing-w|-n 431 -s 427" "missing-s|-n 431 -w $REPO" "unknown-option|-n 431 -w $REPO -s 427 -z"; do
  name=${usage%%|*}
  args=${usage#*|}
  # shellcheck disable=SC2086
  sh "$SCRIPT" $args >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
  RC=$?
  assert_exit "usage-$name exit" 2 "$RC"
  assert_empty "usage-$name stdout" "$TEST_TMP/out"
  assert_nonempty "usage-$name stderr" "$TEST_TMP/err"
  assert_grep "usage-$name message" 'usage' "$TEST_TMP/err"
done

# Case 8: -b origin/main given explicitly matches the default on the shared all-good fixture.
write_pr_json "$JSON" OPEN false MERGEABLE "$FIX_HEAD" "$GOOD_ROLLUP"
sh "$SCRIPT" -n 431 -w "$REPO" -s 427 -b origin/main >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
RC=$?
assert_case "base-ref-accepted" 0 "$TEST_TMP/want-good"

# Case 9: the ci line. Each entry's effective state is its conclusion when non-empty, else its
# status (CheckRun); a StatusContext uses its state. Only SUCCESS passes.
check_ci ci-in-progress 1 '[{"__typename":"CheckRun","name":"build","status":"IN_PROGRESS","conclusion":""}]' \
  "FAIL ci: 1 of 1 not successful: build=IN_PROGRESS"

check_ci ci-failure 1 '[{"__typename":"CheckRun","name":"build","status":"COMPLETED","conclusion":"FAILURE"}]' \
  "FAIL ci: 1 of 1 not successful: build=FAILURE"

check_ci ci-neutral 1 '[{"__typename":"CheckRun","name":"build","status":"COMPLETED","conclusion":"NEUTRAL"}]' \
  "FAIL ci: 1 of 1 not successful: build=NEUTRAL"

check_ci ci-only-skipped 1 '[{"__typename":"CheckRun","name":"build","status":"COMPLETED","conclusion":"SKIPPED"}]' \
  "FAIL ci: 1 of 1 not successful: build=SKIPPED"

check_ci ci-success-and-skipped 1 '[{"__typename":"CheckRun","name":"build","status":"COMPLETED","conclusion":"SUCCESS"},{"__typename":"CheckRun","name":"lint","status":"COMPLETED","conclusion":"SKIPPED"}]' \
  "FAIL ci: 1 of 2 not successful: lint=SKIPPED"

check_ci ci-empty-array 1 '[]' "FAIL ci: no checks"

# A missing statusCheckRollup field is the same as an empty rollup: FAIL ci: no checks.
printf '%s\n' "{\"number\":431,\"state\":\"OPEN\",\"isDraft\":false,\"mergeable\":\"MERGEABLE\",\"headRefOid\":\"$FIX_HEAD\",\"body\":\"\"}" > "$JSON"
sh "$SCRIPT" -n 431 -w "$REPO" -s 427 >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
RC=$?
printf '%s\n' "OK state: OPEN" "OK draft: false" "OK mergeable: MERGEABLE" "OK head: $FIX_HEAD" \
  "FAIL ci: no checks" "$NOTE_LINE" "OK branch: behind 0, ahead 1" > "$TEST_TMP/want-ci-missing-field"
assert_case "ci-missing-field" 1 "$TEST_TMP/want-ci-missing-field"

# StatusContext entries: a SUCCESS state passes, a PENDING state fails with the context name.
check_ci ci-status-context-success 0 '[{"__typename":"StatusContext","context":"lint","state":"SUCCESS"}]' \
  "OK ci: 1 checks successful"

check_ci ci-status-context-pending 1 '[{"__typename":"StatusContext","context":"lint","state":"PENDING"}]' \
  "FAIL ci: 1 of 1 not successful: lint=PENDING"

# Two failing entries are both listed, in input order, comma-separated with no spaces.
check_ci ci-two-failing 1 '[{"__typename":"CheckRun","name":"build","status":"COMPLETED","conclusion":"FAILURE"},{"__typename":"CheckRun","name":"test","status":"COMPLETED","conclusion":"SUCCESS"},{"__typename":"StatusContext","context":"lint","state":"PENDING"}]' \
  "FAIL ci: 2 of 3 not successful: build=FAILURE,lint=PENDING"

# Case 10: the branch line. check_branch <name> <worktree> <expected exit> <expected branch line>
# [script args]: runs the check on one worktree with a PR document whose head is that worktree's HEAD
# and an all-good rollup. The other lines must be OK. Stdout is compared exactly; stderr is not checked
# because git's own fetch messages may appear there.
check_branch() {
  _bname=$1
  _bwt=$2
  _bexit=$3
  _bline=$4
  shift 4
  _bhead=$(git -C "$_bwt" rev-parse HEAD) || exit 2
  write_pr_json "$JSON" OPEN false MERGEABLE "$_bhead" "$GOOD_ROLLUP"
  sh "$SCRIPT" -n 431 -w "$_bwt" -s 427 "$@" >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
  RC=$?
  printf '%s\n' "OK state: OPEN" "OK draft: false" "OK mergeable: MERGEABLE" "OK head: $_bhead" \
    "OK ci: 1 checks successful" "$NOTE_LINE" "$_bline" > "$TEST_TMP/want-$_bname"
  assert_exit "$_bname exit" "$_bexit" "$RC"
  assert_file_eq "$_bname lines" "$TEST_TMP/want-$_bname" "$TEST_TMP/out"
}

# Case 10a: the local origin/main is stale (base). origin advanced by two commits, and the branch has
# five commits on top of the fork point. The script must fetch before it reads position: behind 2
# (only a fetch makes origin/main two commits ahead), ahead 5.
make_origin_clone "$TEST_TMP/stale" 5 || exit 2
advance_origin "$TEST_TMP/stale" 2 || exit 2
check_branch branch-stale-fetched "$TEST_TMP/stale" 1 "FAIL branch: behind 2, ahead 5"

# Case 10b: the local origin/main is current: behind 0, ahead 5.
make_origin_clone "$TEST_TMP/ahead5" 5 || exit 2
check_branch branch-ahead-only "$TEST_TMP/ahead5" 0 "OK branch: behind 0, ahead 5"

# Case 10c: the remote URL is a path that does not exist. The NOTE line still prints, then the fetch
# failure. Other lines stay OK.
make_origin_clone "$TEST_TMP/gone" 1 || exit 2
git_c "$TEST_TMP/gone" remote set-url origin "$TEST_TMP/no-such-origin.git" || exit 2
check_branch branch-fetch-failed "$TEST_TMP/gone" 1 "FAIL branch: fetch failed"

# Case 10d: -b origin/main given explicitly on the stale fixture behaves like the default: behind 2,
# ahead 5. A fresh stale fixture keeps this case independent of case 10a's fetch.
make_origin_clone "$TEST_TMP/stale-explicit" 5 || exit 2
advance_origin "$TEST_TMP/stale-explicit" 2 || exit 2
check_branch branch-explicit-base "$TEST_TMP/stale-explicit" 1 "FAIL branch: behind 2, ahead 5" -b origin/main

# Case 10e: a base ref without a slash names no remote, so it is a usage error: exit 2, usage message
# on stderr, nothing on stdout. The all-good document is written so a script that ignores the error
# would print OK lines and exit 0.
write_pr_json "$JSON" OPEN false MERGEABLE "$(git -C "$REPO" rev-parse HEAD)" "$GOOD_ROLLUP"
sh "$SCRIPT" -n 431 -w "$REPO" -s 427 -b main >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
RC=$?
assert_exit "base-no-slash exit" 2 "$RC"
assert_empty "base-no-slash stdout" "$TEST_TMP/out"
assert_nonempty "base-no-slash stderr" "$TEST_TMP/err"
assert_grep "base-no-slash message" 'usage' "$TEST_TMP/err"

test_summary
