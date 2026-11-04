#!/bin/sh
# Fixture tests for handback-check.sh: the state, draft, mergeable, head, ci, branch, closing, footer,
# coauthor, ascii and inline lines, the gh failure path, the fetch NOTE line and usage errors. No network: the gh
# command is a stub that prints a JSON fixture file, and the branch fixtures use a local bare repository
# as origin.
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

# The four body lines of the all-good fixture: one commit on the branch, no trailer, plain footer.
CLOSE_OK='OK closing: names #427'
FOOT_OK='OK footer: Generated with Claude Code'
CO_NONE1='OK coauthor: none in body or 1 commits'
ASCII_OK='OK ascii: body is ASCII'
# INLINE_NONE: the inline line when the worktree has no plan.md (no clause to read).
INLINE_NONE='OK inline: none'
GOOD_CHECKS=$(printf '%s\n' "$CLOSE_OK" "$FOOT_OK" "$CO_NONE1" "$ASCII_OK" "$INLINE_NONE")

# Non-ASCII bytes are written as printf escapes so this file stays ASCII. ROBOT is U+1F916 (an emoji)
# and DASH is U+2014 (an em-dash).
ROBOT=$(printf '\360\237\244\226')
DASH=$(printf '\342\200\224')

# GOOD_BODY: the all-good PR body (a closing reference, text and the plain footer).
GOOD_BODY=$TEST_TMP/body-good
printf '%s\n' 'Closes #427' '' 'Summary of the change.' '' 'Generated with Claude Code' > "$GOOD_BODY" || exit 2

write_gh_stub "$STUB" || exit 2

# make_origin_clone <dir> <ahead> [base trailer]: a bare origin at <dir>.origin.git seeded with main, and a
# clone at <dir> on branch agent/s427-t1-tw with <ahead> commits on top of origin/main. The optional third
# argument is a trailer line for the seed commit on main. Sets FIX_BASE to the origin/main sha and
# FIX_HEAD to the clone HEAD.
make_origin_clone() {
  _seed=$1.seed
  _origin=$1.origin.git
  git init -q -b main "$_seed" || return 1
  printf '%s\n' 'base' > "$_seed/file.txt" || return 1
  git_c "$_seed" add -A || return 1
  if [ -n "${3:-}" ]; then
    git_c "$_seed" commit -q -m base -m "$3" || return 1
  else
    git_c "$_seed" commit -q -m base || return 1
  fi
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

# commit_line <dir> <subject> [trailer]: append a line to file.txt and commit it on the branch. The optional
# trailer is a second paragraph of the commit message.
commit_line() {
  printf '%s\n' "$2" >> "$1/file.txt" || return 1
  if [ -n "${3:-}" ]; then
    git_c "$1" commit -q -a -m "$2" -m "$3" || return 1
  else
    git_c "$1" commit -q -a -m "$2" || return 1
  fi
}

# short_sha <dir> <rev>: the first seven characters of the commit that <rev> names in the repository at <dir>.
short_sha() {
  _full=$(git -C "$1" rev-parse "$2") || return 1
  printf '%s\n' "$_full" | awk '{ print substr($0, 1, 7) }'
}

make_origin_clone "$REPO" 1 || exit 2

# run_script [args]: run the script with the arguments and no stdin. Sets RC, leaves stdout in
# $TEST_TMP/out and stderr in $TEST_TMP/err.
run_script() {
  sh "$SCRIPT" "$@" >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
  RC=$?
}

# check_pr <state> <isDraft> <mergeable> <headRefOid> [rollup JSON]: write the PR document, then run
# the check with the default arguments. The rollup defaults to GOOD_ROLLUP and the body to GOOD_BODY.
# Sets RC and leaves stdout in $TEST_TMP/out, stderr in $TEST_TMP/err.
check_pr() {
  write_pr_json "$JSON" "$1" "$2" "$3" "$4" "${5:-$GOOD_ROLLUP}" "$GOOD_BODY"
  run_script -n 431 -w "$REPO" -s 427
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
    "$NOTE_LINE" "OK branch: behind 0, ahead 1" "$GOOD_CHECKS" > "$TEST_TMP/want-$1"
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
OK closing: names #427
OK footer: Generated with Claude Code
OK coauthor: none in body or 1 commits
OK ascii: body is ASCII
OK inline: none
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
OK closing: names #427
OK footer: Generated with Claude Code
OK coauthor: none in body or 1 commits
OK ascii: body is ASCII
OK inline: none
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
OK closing: names #427
OK footer: Generated with Claude Code
OK coauthor: none in body or 1 commits
OK ascii: body is ASCII
OK inline: none
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
OK closing: names #427
OK footer: Generated with Claude Code
OK coauthor: none in body or 1 commits
OK ascii: body is ASCII
OK inline: none
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
OK closing: names #427
OK footer: Generated with Claude Code
OK coauthor: none in body or 1 commits
OK ascii: body is ASCII
OK inline: none
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
OK closing: names #427
OK footer: Generated with Claude Code
OK coauthor: none in body or 1 commits
OK ascii: body is ASCII
OK inline: none
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
FAIL closing: gh failed
FAIL footer: gh failed
FAIL coauthor: gh failed
FAIL ascii: gh failed
EOF
assert_case "gh-exit-nonzero" 1 "$TEST_TMP/want-ghfail"

# Case 6b: the gh stub prints invalid JSON. The same ten FAIL lines and no crash message.
printf '%s\n' 'not json at all' > "$TEST_TMP/bad.json"
STUB_JSON=$TEST_TMP/bad.json sh "$SCRIPT" -n 431 -w "$REPO" -s 427 >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
RC=$?
assert_case "gh-invalid-json" 1 "$TEST_TMP/want-ghfail"

# Case 7: usage errors exit 2, print a usage message on stderr and nothing on stdout.
# Each run uses the all-good document so a script that ignores the usage error would print OK lines.
write_pr_json "$JSON" OPEN false MERGEABLE "$FIX_HEAD" "$GOOD_ROLLUP" "$GOOD_BODY"
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
write_pr_json "$JSON" OPEN false MERGEABLE "$FIX_HEAD" "$GOOD_ROLLUP" "$GOOD_BODY"
run_script -n 431 -w "$REPO" -s 427 -b origin/main
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
_gb=$(jq -Rs . < "$GOOD_BODY") || exit 2
printf '%s\n' "{\"number\":431,\"state\":\"OPEN\",\"isDraft\":false,\"mergeable\":\"MERGEABLE\",\"headRefOid\":\"$FIX_HEAD\",\"body\":$_gb}" > "$JSON"
run_script -n 431 -w "$REPO" -s 427
printf '%s\n' "OK state: OPEN" "OK draft: false" "OK mergeable: MERGEABLE" "OK head: $FIX_HEAD" \
  "FAIL ci: no checks" "$NOTE_LINE" "OK branch: behind 0, ahead 1" "$GOOD_CHECKS" > "$TEST_TMP/want-ci-missing-field"
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
# and an all-good rollup and body. The other lines must be OK; the coauthor count is the commit count
# on the branch. Stdout is compared exactly; stderr is not checked because git's own fetch messages may
# appear there.
check_branch() {
  _bname=$1
  _bwt=$2
  _bexit=$3
  _bline=$4
  shift 4
  _bhead=$(git -C "$_bwt" rev-parse HEAD) || exit 2
  _bn=$(git -C "$_bwt" rev-list --count "origin/main..HEAD") || exit 2
  write_pr_json "$JSON" OPEN false MERGEABLE "$_bhead" "$GOOD_ROLLUP" "$GOOD_BODY"
  run_script -n 431 -w "$_bwt" -s 427 "$@"
  printf '%s\n' "OK state: OPEN" "OK draft: false" "OK mergeable: MERGEABLE" "OK head: $_bhead" \
    "OK ci: 1 checks successful" "$NOTE_LINE" "$_bline" "$CLOSE_OK" "$FOOT_OK" \
    "OK coauthor: none in body or $_bn commits" "$ASCII_OK" "$INLINE_NONE" > "$TEST_TMP/want-$_bname"
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

# Case 10d2: the local origin/main is behind by exactly one commit. origin advanced by one, and the
# branch has three commits on top of the fork point. Only a fetch makes origin/main one commit ahead:
# behind 1, ahead 3. The behind boundary (behind > 0 fails) is exercised at 1, not only at 2.
make_origin_clone "$TEST_TMP/behind1" 3 || exit 2
advance_origin "$TEST_TMP/behind1" 1 || exit 2
check_branch branch-behind-one "$TEST_TMP/behind1" 1 "FAIL branch: behind 1, ahead 3"

# Case 10e: a base ref without a slash names no remote, so it is a usage error: exit 2, usage message
# on stderr, nothing on stdout. The all-good document is written so a script that ignores the error
# would print OK lines and exit 0.
write_pr_json "$JSON" OPEN false MERGEABLE "$(git -C "$REPO" rev-parse HEAD)" "$GOOD_ROLLUP" "$GOOD_BODY"
run_script -n 431 -w "$REPO" -s 427 -b main
assert_exit "base-no-slash exit" 2 "$RC"
assert_empty "base-no-slash stdout" "$TEST_TMP/out"
assert_nonempty "base-no-slash stderr" "$TEST_TMP/err"
assert_grep "base-no-slash message" 'usage' "$TEST_TMP/err"

# Case 11: the closing, footer, coauthor and ascii lines. body_case <name> <worktree> <expected exit>
# <body file> <closing line> <footer line> <coauthor line> <ascii line>: runs the check on the worktree
# with the body file as the PR body. The head is the worktree HEAD and the rollup is all good, so the
# state..branch lines are OK; the four body lines are the ones given. Exact stdout and exit code.
body_case() {
  _bhead=$(git -C "$2" rev-parse HEAD) || exit 2
  _bahead=$(git -C "$2" rev-list --count "origin/main..HEAD") || exit 2
  write_pr_json "$JSON" OPEN false MERGEABLE "$_bhead" "$GOOD_ROLLUP" "$4"
  run_script -n 431 -w "$2" -s 427
  printf '%s\n' "OK state: OPEN" "OK draft: false" "OK mergeable: MERGEABLE" "OK head: $_bhead" \
    "OK ci: 1 checks successful" "$NOTE_LINE" "OK branch: behind 0, ahead $_bahead" \
    "$5" "$6" "$7" "$8" "$INLINE_NONE" > "$TEST_TMP/want-$1"
  assert_case "$1" "$3" "$TEST_TMP/want-$1"
}

# Case 11a: a markdown-link footer passes.
printf '%s\n' 'Closes #427' '' 'Summary.' '' 'Generated with [Claude Code](https://claude.com/claude-code)' > "$TEST_TMP/body-md"
body_case footer-markdown-link "$REPO" 0 "$TEST_TMP/body-md" "$CLOSE_OK" \
  "OK footer: Generated with [Claude Code](https://claude.com/claude-code)" "$CO_NONE1" "$ASCII_OK"

# Case 11b: a CRLF body passes; the CR bytes are stripped before the closing and footer checks.
printf 'Closes #427\r\n\r\nSummary.\r\n\r\nGenerated with Claude Code\r\n' > "$TEST_TMP/body-crlf"
body_case crlf-body "$REPO" 0 "$TEST_TMP/body-crlf" "$CLOSE_OK" "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 11c: trailing spaces and a tab on the footer line are stripped; the footer still passes.
printf 'Closes #427\n\nSummary.\n\nGenerated with Claude Code \t \n' > "$TEST_TMP/body-trail"
body_case footer-trailing-blanks "$REPO" 0 "$TEST_TMP/body-trail" "$CLOSE_OK" "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 11d: empty lines after the footer are skipped: the last non-empty line is the footer.
printf 'Closes #427\n\nSummary.\n\nGenerated with Claude Code\n\n\n' > "$TEST_TMP/body-trail-lines"
body_case footer-trailing-empty-lines "$REPO" 0 "$TEST_TMP/body-trail-lines" "$CLOSE_OK" "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 11e: an emoji prefix on the footer line fails the footer and the ascii check on that line (line 5).
printf '%s\n' 'Closes #427' '' 'Summary.' '' "$ROBOT Generated with Claude Code" > "$TEST_TMP/body-emoji-footer"
body_case footer-emoji-prefix "$REPO" 1 "$TEST_TMP/body-emoji-footer" "$CLOSE_OK" \
  "FAIL footer: last line is \"$ROBOT Generated with Claude Code\"" "$CO_NONE1" "FAIL ascii: non-ASCII byte on line 5"

# Case 11f: text after the footer makes the last non-empty line the failing footer value.
printf '%s\n' 'Closes #427' '' 'Summary.' '' 'Generated with Claude Code' 'See the diff.' > "$TEST_TMP/body-after"
body_case footer-text-after "$REPO" 1 "$TEST_TMP/body-after" "$CLOSE_OK" \
  'FAIL footer: last line is "See the diff."' "$CO_NONE1" "$ASCII_OK"

# Case 11g: a footer in the middle of the body fails; the closing reference after it still passes.
printf '%s\n' 'Generated with Claude Code' '' 'Summary.' '' 'Closes #427' > "$TEST_TMP/body-mid"
body_case footer-mid-body "$REPO" 1 "$TEST_TMP/body-mid" "$CLOSE_OK" \
  'FAIL footer: last line is "Closes #427"' "$CO_NONE1" "$ASCII_OK"

# Case 11h: an empty body fails the closing and footer lines; coauthor and ascii pass on no bytes.
: > "$TEST_TMP/body-empty"
body_case body-empty "$REPO" 1 "$TEST_TMP/body-empty" "FAIL closing: no closing keyword for #427" \
  "FAIL footer: empty body" "$CO_NONE1" "$ASCII_OK"

# Case 11i: a second closing reference to another issue fails with its number.
printf '%s\n' 'Closes #427' '' 'fixes #12' '' 'Generated with Claude Code' > "$TEST_TMP/body-fixes12"
body_case closing-fixes-other "$REPO" 1 "$TEST_TMP/body-fixes12" "FAIL closing: also names #12" \
  "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 11j: a comma list that adds another issue fails with that issue's number.
printf '%s\n' 'Closes #427, #12' '' 'Generated with Claude Code' > "$TEST_TMP/body-comma12"
body_case closing-comma-other "$REPO" 1 "$TEST_TMP/body-comma12" "FAIL closing: also names #12" \
  "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 11k: 4270 is a different whole number from 427: a near-miss fails.
printf '%s\n' 'Closes #4270' '' 'Generated with Claude Code' > "$TEST_TMP/body-4270"
body_case closing-near-miss "$REPO" 1 "$TEST_TMP/body-4270" "FAIL closing: also names #4270" \
  "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 11l: a cross-repository reference counts as another issue and is written as is.
printf '%s\n' 'Resolves owner/repo#427' '' 'Generated with Claude Code' > "$TEST_TMP/body-owner"
body_case closing-owner-repo "$REPO" 1 "$TEST_TMP/body-owner" "FAIL closing: also names owner/repo#427" \
  "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 11m: no closing keyword before the story number fails with no keyword.
printf '%s\n' 'Refers to #427.' '' 'Generated with Claude Code' > "$TEST_TMP/body-nokw"
body_case closing-no-keyword "$REPO" 1 "$TEST_TMP/body-nokw" "FAIL closing: no closing keyword for #427" \
  "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 11n: the keyword counts in lower case.
printf '%s\n' 'closes #427' '' 'Generated with Claude Code' > "$TEST_TMP/body-lower"
body_case closing-lower "$REPO" 0 "$TEST_TMP/body-lower" "$CLOSE_OK" "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 11o: the keyword counts in upper case.
printf '%s\n' 'RESOLVES #427' '' 'Generated with Claude Code' > "$TEST_TMP/body-upper"
body_case closing-upper "$REPO" 0 "$TEST_TMP/body-upper" "$CLOSE_OK" "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 11p: the keyword counts in mixed case.
printf '%s\n' 'cLoSeS #427' '' 'Generated with Claude Code' > "$TEST_TMP/body-mixed"
body_case closing-mixed "$REPO" 0 "$TEST_TMP/body-mixed" "$CLOSE_OK" "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 11q: an optional colon between the keyword and the reference counts.
printf '%s\n' 'Closes: #427' '' 'Generated with Claude Code' > "$TEST_TMP/body-colon"
body_case closing-colon "$REPO" 0 "$TEST_TMP/body-colon" "$CLOSE_OK" "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 11r: the same story reference twice is fine: the numbers are unique.
printf '%s\n' 'Closes #427' '' 'Closes #427' '' 'Generated with Claude Code' > "$TEST_TMP/body-twice"
body_case closing-twice "$REPO" 0 "$TEST_TMP/body-twice" "$CLOSE_OK" "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 11s: a Co-Authored-By line in the body (mixed case) fails the coauthor line.
printf '%s\n' 'Closes #427' '' 'Summary.' '' 'Co-Authored-By: Claude <noreply@example.com>' '' 'Generated with Claude Code' > "$TEST_TMP/body-coa"
body_case coauthor-body "$REPO" 1 "$TEST_TMP/body-coa" "$CLOSE_OK" "$FOOT_OK" "FAIL coauthor: body" "$ASCII_OK"

# Case 11t: leading spaces and lower case still start the trailer line: it fails.
printf '%s\n' 'Closes #427' '' '  co-authored-by: Someone <s@example.com>' '' 'Generated with Claude Code' > "$TEST_TMP/body-coa-indent"
body_case coauthor-body-indented "$REPO" 1 "$TEST_TMP/body-coa-indent" "$CLOSE_OK" "$FOOT_OK" "FAIL coauthor: body" "$ASCII_OK"

# Case 11u: the trailer text in the middle of a line does not start the line: it passes.
printf '%s\n' 'Closes #427' '' 'Mention co-authored-by: in the middle of a line.' '' 'Generated with Claude Code' > "$TEST_TMP/body-coa-mid"
body_case coauthor-mid-line "$REPO" 0 "$TEST_TMP/body-coa-mid" "$CLOSE_OK" "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 11v: an em-dash on line 3 fails the ascii line with that line number.
printf '%s\n' 'Closes #427' '' "Summary $DASH text." '' 'Generated with Claude Code' > "$TEST_TMP/body-dash"
body_case ascii-em-dash "$REPO" 1 "$TEST_TMP/body-dash" "$CLOSE_OK" "$FOOT_OK" "$CO_NONE1" \
  "FAIL ascii: non-ASCII byte on line 3"

# Case 11w: an emoji on line 3 fails the ascii line with that line number.
printf '%s\n' 'Closes #427' '' "Summary $ROBOT text." '' 'Generated with Claude Code' > "$TEST_TMP/body-emoji"
body_case ascii-emoji "$REPO" 1 "$TEST_TMP/body-emoji" "$CLOSE_OK" "$FOOT_OK" "$CO_NONE1" \
  "FAIL ascii: non-ASCII byte on line 3"

# Case 11x: with a non-ASCII byte on line 3 and again on line 5, the first offending line is named.
printf '%s\n' 'Closes #427' '' "Summary $DASH text." '' "Note $ROBOT text." '' 'Generated with Claude Code' > "$TEST_TMP/body-two-bad"
body_case ascii-first-line "$REPO" 1 "$TEST_TMP/body-two-bad" "$CLOSE_OK" "$FOOT_OK" "$CO_NONE1" \
  "FAIL ascii: non-ASCII byte on line 3"

# Case 11y: a tab is whitespace and passes the ascii line.
printf 'Closes #427\n\n\tIndented with a tab.\n\nGenerated with Claude Code\n' > "$TEST_TMP/body-tab"
body_case ascii-tab "$REPO" 0 "$TEST_TMP/body-tab" "$CLOSE_OK" "$FOOT_OK" "$CO_NONE1" "$ASCII_OK"

# Case 12: the coauthor line also reads the commit messages in base..HEAD. One branch commit with the
# trailer fails with that commit's short sha. The fixture has no body trailer and one commit.
make_origin_clone "$TEST_TMP/coa-one" 0 || exit 2
commit_line "$TEST_TMP/coa-one" 'trailer one' 'Co-Authored-By: Claude <noreply@example.com>' || exit 2
_s1=$(short_sha "$TEST_TMP/coa-one" HEAD) || exit 2
body_case coauthor-one-commit "$TEST_TMP/coa-one" 1 "$GOOD_BODY" "$CLOSE_OK" "$FOOT_OK" \
  "FAIL coauthor: commit $_s1" "$ASCII_OK"

# Case 13: two branch commits with trailers both fail, listed newest first (git log order), joined by "; ".
make_origin_clone "$TEST_TMP/coa-two" 0 || exit 2
commit_line "$TEST_TMP/coa-two" 'first' 'Co-Authored-By: A <a@example.com>' || exit 2
commit_line "$TEST_TMP/coa-two" 'second' 'co-authored-by: B <b@example.com>' || exit 2
_new=$(short_sha "$TEST_TMP/coa-two" HEAD) || exit 2
_old=$(short_sha "$TEST_TMP/coa-two" HEAD~1) || exit 2
body_case coauthor-two-commits "$TEST_TMP/coa-two" 1 "$GOOD_BODY" "$CLOSE_OK" "$FOOT_OK" \
  "FAIL coauthor: commit $_new; commit $_old" "$ASCII_OK"

# Case 14: a trailer in the body and a trailer in one commit list both: "body; commit <sha>".
make_origin_clone "$TEST_TMP/coa-both" 0 || exit 2
commit_line "$TEST_TMP/coa-both" 'with trailer' 'Co-Authored-By: C <c@example.com>' || exit 2
_sb=$(short_sha "$TEST_TMP/coa-both" HEAD) || exit 2
printf '%s\n' 'Closes #427' '' 'Co-Authored-By: Claude <noreply@example.com>' '' 'Generated with Claude Code' > "$TEST_TMP/body-coa-both"
body_case coauthor-body-and-commit "$TEST_TMP/coa-both" 1 "$TEST_TMP/body-coa-both" "$CLOSE_OK" "$FOOT_OK" \
  "FAIL coauthor: body; commit $_sb" "$ASCII_OK"

# Case 15: two clean branch commits: the count reads 2 and the line passes.
make_origin_clone "$TEST_TMP/coa-clean" 0 || exit 2
commit_line "$TEST_TMP/coa-clean" 'clean one' || exit 2
commit_line "$TEST_TMP/coa-clean" 'clean two' || exit 2
body_case coauthor-clean-two "$TEST_TMP/coa-clean" 0 "$GOOD_BODY" "$CLOSE_OK" "$FOOT_OK" \
  "OK coauthor: none in body or 2 commits" "$ASCII_OK"

# Case 16: no branch commits (HEAD is origin/main): the count reads 0 and the line passes.
make_origin_clone "$TEST_TMP/coa-zero" 0 || exit 2
body_case coauthor-zero-commits "$TEST_TMP/coa-zero" 0 "$GOOD_BODY" "$CLOSE_OK" "$FOOT_OK" \
  "OK coauthor: none in body or 0 commits" "$ASCII_OK"

# Case 17: a trailer on the base commit is outside base..HEAD and is not read: the count reads 0 and passes.
make_origin_clone "$TEST_TMP/coa-base" 0 'Co-Authored-By: Base <b@example.com>' || exit 2
body_case coauthor-base-trailer-ignored "$TEST_TMP/coa-base" 0 "$GOOD_BODY" "$CLOSE_OK" "$FOOT_OK" \
  "OK coauthor: none in body or 0 commits" "$ASCII_OK"

# Case 18: the inline line. INL is a clone with two branch commits on top of origin/main. Commit 1 (INL_BASE)
# adds README.md with four lines (4 added). Commit 2 (INL_SHA) keeps two README.md lines, deletes two and adds
# four (README.md 4 added, 2 deleted) and adds notes.txt with three lines (3 added). The other lines are the
# all-good lines for the worktree; inline_case compares the whole stdout with the expected inline lines of
# the named case and checks the exit code. inline_expect <name> [lines...]: write the expected inline lines.
inline_expect() {
  _ename=$1
  shift
  printf '%s\n' "$@" > "$TEST_TMP/exp-$_ename"
}

# inline_case <name> <worktree> <expected exit> [script args]: run the check on the worktree with the all-good
# document and compare stdout with the state..ascii lines followed by $TEST_TMP/exp-<name>.
inline_case() {
  _iname=$1
  _iwt=$2
  _iexit=$3
  shift 3
  _ihead=$(git -C "$_iwt" rev-parse HEAD) || exit 2
  _ibn=$(git -C "$_iwt" rev-list --count "origin/main..HEAD") || exit 2
  write_pr_json "$JSON" OPEN false MERGEABLE "$_ihead" "$GOOD_ROLLUP" "$GOOD_BODY"
  run_script -n 431 -w "$_iwt" -s 427 "$@"
  printf '%s\n' "OK state: OPEN" "OK draft: false" "OK mergeable: MERGEABLE" "OK head: $_ihead" \
    "OK ci: 1 checks successful" "$NOTE_LINE" "OK branch: behind 0, ahead $_ibn" "$CLOSE_OK" "$FOOT_OK" \
    "OK coauthor: none in body or $_ibn commits" "$ASCII_OK" > "$TEST_TMP/want-$_iname"
  cat "$TEST_TMP/exp-$_iname" >> "$TEST_TMP/want-$_iname"
  assert_case "$_iname" "$_iexit" "$TEST_TMP/want-$_iname"
}

# write_plan <file> [lines...]: write each argument as one line of the file.
write_plan() {
  _wf=$1
  shift
  printf '%s\n' "$@" > "$_wf"
}

INL=$TEST_TMP/inl
make_origin_clone "$INL" 0 || exit 2
printf '%s\n' one two three four > "$INL/README.md" || exit 2
git_c "$INL" add -A || exit 2
git_c "$INL" commit -q -m 'readme base' || exit 2
INL_BASE=$(short_sha "$INL" HEAD) || exit 2
printf '%s\n' one two five six seven eight > "$INL/README.md" || exit 2
printf '%s\n' 'note one' 'note two' 'note three' > "$INL/notes.txt" || exit 2
git_c "$INL" add -A || exit 2
git_c "$INL" commit -q -m 'readme and notes' || exit 2
INL_SHA=$(short_sha "$INL" HEAD) || exit 2

# Case 18a: a clause with the hash on its own inline commits: line. README.md is 4 + 2 = 6; notes.txt has no clause
# and is ignored.
write_plan "$INL/plan.md" 'Todo 1: example' 'lane: inline 6 lines in README.md' "inline commits: $INL_SHA"
inline_expect own-line-ok 'OK inline: README.md 6 lines'
inline_case own-line-ok "$INL" 0

# Case 18b: the same clause with the hash on the lane line after the clause.
write_plan "$INL/plan.md" 'lane: inline 6 lines in README.md inline commits: '"$INL_SHA"
inline_expect lane-line-ok 'OK inline: README.md 6 lines'
inline_case lane-line-ok "$INL" 0

# Case 18c, 18d, 18e: the plan count 8, 5 and 7 each differ from numstat 6 and fail with both numbers.
write_plan "$INL/plan.md" 'lane: inline 8 lines in README.md' "inline commits: $INL_SHA"
inline_expect plan-high 'FAIL inline: README.md plan 8, numstat 6'
inline_case plan-high "$INL" 1

write_plan "$INL/plan.md" 'lane: inline 5 lines in README.md' "inline commits: $INL_SHA"
inline_expect plan-low 'FAIL inline: README.md plan 5, numstat 6'
inline_case plan-low "$INL" 1

write_plan "$INL/plan.md" 'lane: inline 7 lines in README.md' "inline commits: $INL_SHA"
inline_expect plan-off-by-one 'FAIL inline: README.md plan 7, numstat 6'
inline_case plan-off-by-one "$INL" 1

# Case 18f: one commit, two files with clauses. notes.txt (plan 2, numstat 3) fails and is listed first because
# its clause comes first; README.md (6) is OK. Lines follow plan order.
write_plan "$INL/plan.md" 'lane: inline 2 lines in notes.txt' 'lane: inline 6 lines in README.md' "inline commits: $INL_SHA"
inline_expect two-file-mixed 'FAIL inline: notes.txt plan 2, numstat 3' 'OK inline: README.md 6 lines'
inline_case two-file-mixed "$INL" 1

# Case 18g: two clauses on one lane line, both OK, listed in plan order.
write_plan "$INL/plan.md" "lane: inline 6 lines in README.md lane: inline 3 lines in notes.txt inline commits: $INL_SHA"
inline_expect two-clauses-one-line 'OK inline: README.md 6 lines' 'OK inline: notes.txt 3 lines'
inline_case two-clauses-one-line "$INL" 0

# Case 18h: two commits for one file add: INL_BASE gives 4 and INL_SHA gives 6, so 10.
write_plan "$INL/plan.md" 'lane: inline 10 lines in README.md' "inline commits: $INL_BASE $INL_SHA"
inline_expect two-commits-one-file 'OK inline: README.md 10 lines'
inline_case two-commits-one-file "$INL" 0

# Case 18i: the same file in two clauses adds the n values: 3 + 3 = 6, one line only.
write_plan "$INL/plan.md" 'lane: inline 3 lines in README.md' 'lane: inline 3 lines in README.md' "inline commits: $INL_SHA"
inline_expect same-file-twice 'OK inline: README.md 6 lines'
inline_case same-file-twice "$INL" 0

# Case 18j: a plan with no clause prints OK inline: none even when it names commits.
write_plan "$INL/plan.md" 'Todo 1: example' "inline commits: $INL_SHA"
inline_expect no-clause 'OK inline: none'
inline_case no-clause "$INL" 0

# Case 18k: no default plan.md in the worktree prints OK inline: none.
rm -f "$INL/plan.md" || exit 2
inline_expect default-plan-absent 'OK inline: none'
inline_case default-plan-absent "$INL" 0

# Case 18l: a -P plan file that is missing fails with its name and exits 1.
inline_expect p-missing 'FAIL inline: plan file missing-plan.md not found'
inline_case p-missing "$INL" 1 -P missing-plan.md

# Case 18m: -P names another file: that file is read, and the default plan.md (which would fail with count 9) is not.
write_plan "$INL/plan.md" 'lane: inline 9 lines in README.md' "inline commits: $INL_SHA"
write_plan "$INL/lane-plan.md" 'lane: inline 6 lines in README.md' "inline commits: $INL_SHA"
inline_expect p-present 'OK inline: README.md 6 lines'
inline_case p-present "$INL" 0 -P lane-plan.md

# Case 18n: a hash that is not a commit fails once with the hash as written; the file line still prints from the
# hashes that resolve.
write_plan "$INL/plan.md" 'lane: inline 6 lines in README.md' "inline commits: deadbee $INL_SHA"
inline_expect unknown-hash 'FAIL inline: hash deadbee not found' 'OK inline: README.md 6 lines'
inline_case unknown-hash "$INL" 1

# Case 18o: a hash named twice (on the lane line and on its own line) counts once: 6, not 12.
write_plan "$INL/plan.md" "lane: inline 6 lines in README.md inline commits: $INL_SHA" "inline commits: $INL_SHA"
inline_expect hash-twice 'OK inline: README.md 6 lines'
inline_case hash-twice "$INL" 0

# Case 18p: a token that is not hex after inline commits: is ignored.
write_plan "$INL/plan.md" 'lane: inline 6 lines in README.md' "inline commits: notahash $INL_SHA"
inline_expect non-hex-token 'OK inline: README.md 6 lines'
inline_case non-hex-token "$INL" 0

# Case 18q: a binary file change counts 0 (numstat prints -): n 0 is OK.
INB=$TEST_TMP/inl-bin
make_origin_clone "$INB" 0 || exit 2
printf 'bin\000ary\n' > "$INB/bin.dat" || exit 2
git_c "$INB" add -A || exit 2
git_c "$INB" commit -q -m 'binary file' || exit 2
INB_SHA=$(short_sha "$INB" HEAD) || exit 2
write_plan "$INB/plan.md" 'lane: inline 0 lines in bin.dat' "inline commits: $INB_SHA"
inline_expect binary-zero 'OK inline: bin.dat 0 lines'
inline_case binary-zero "$INB" 0

# Case 18r: the same binary change with n 1 fails: the binary count is 0, not 1.
write_plan "$INB/plan.md" 'lane: inline 1 lines in bin.dat' "inline commits: $INB_SHA"
inline_expect binary-one 'FAIL inline: bin.dat plan 1, numstat 0'
inline_case binary-one "$INB" 1

test_summary
