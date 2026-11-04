#!/bin/sh
# Fixture tests for closeout-check.sh: the merged, fetch NOTE, ancestry, patch and worktree lines, the
# -x and -P options, the gh failure paths, usage errors (exit 2) and an unchanged-repositories check.
# No network: the gh command is a stub that prints a JSON fixture file, and every repository is a clone
# of a local bare origin under the test temp directory.
# CLOSEOUT_CHECK=<path> substitutes another script (used to prove a test can fail).
. "$(dirname "$0")/lib.sh"

SCRIPT=${CLOSEOUT_CHECK:-$(dirname "$0")/../closeout-check.sh}
STUB=$TEST_TMP/gh-stub
JSON=$TEST_TMP/merge.json
export CLOSEOUT_GH=$STUB STUB_JSON=$JSON
unset STUB_EXIT
write_gh_stub "$STUB" || exit 2

FX_PREFIX=s427-t6-tw
FX_BRANCH=agent/s427-t6-tw
FX_RECON=s427-t6-rc

# NOTE_FETCH: the fetch line printed after the merged line in every run, for the fixture branch.
NOTE_FETCH="NOTE fetch: ran git fetch origin main $FX_BRANCH"
# PATCH_OK: the patch line when the squash and the branch diff are equal.
PATCH_OK='OK patch: squash equals branch diff'

# short7 <sha>: the first seven characters of a sha.
short7() {
  printf '%s\n' "$1" | awk '{ print substr($0, 1, 7) }'
}

# write_merge <state> <sha or null>: the gh pr view document for the merge check.
write_merge() {
  if [ "$2" = null ]; then
    _mc=null
  else
    _mc="{\"oid\":\"$2\"}"
  fi
  printf '{"state":"%s","mergeCommit":%s}\n' "$1" "$_mc" > "$JSON" || exit 2
}

# make_fixture <dir> [squash extra line]: a bare origin at <dir>/origin.git seeded with main (file.txt and a
# .gitignore that ignores *.log), a root clone at <dir>/root on main, the branch agent/s427-t6-tw with one
# commit in the runner worktree at <dir>/root/.worktrees/s427-t6-tw (plan.md untracked there), the branch
# pushed to origin, and the squash commit pushed to origin main by a clone at <dir>/upstream. The squash
# holds the same file change as the branch plus the optional extra line. The root keeps its old origin/main
# until a fetch. Sets FX_ROOT, FX_WT, FX_ORIGIN, FX_H (branch tip) and FX_S (squash commit).
make_fixture() {
  _d=$1
  mkdir "$_d" || return 1
  git init -q -b main "$_d/seed" || return 1
  printf '%s\n' base > "$_d/seed/file.txt" || return 1
  printf '%s\n' '*.log' > "$_d/seed/.gitignore" || return 1
  git_c "$_d/seed" add -A || return 1
  git_c "$_d/seed" commit -q -m base || return 1
  git init -q --bare -b main "$_d/origin.git" || return 1
  git_c "$_d/seed" push -q "$_d/origin.git" main || return 1
  git clone -q "$_d/origin.git" "$_d/root" || return 1
  FX_ROOT=$_d/root
  FX_WT=$_d/root/.worktrees/$FX_PREFIX
  FX_ORIGIN=$_d/origin.git
  git_c "$FX_ROOT" worktree add -q -b "$FX_BRANCH" "$FX_WT" main || return 1
  printf '%s\n' feature >> "$FX_WT/file.txt" || return 1
  git_c "$FX_WT" commit -q -a -m feature || return 1
  FX_H=$(git -C "$FX_ROOT" rev-parse "$FX_BRANCH") || return 1
  git_c "$FX_ROOT" push -q origin "$FX_BRANCH" || return 1
  printf '%s\n' plan > "$FX_WT/plan.md" || return 1
  git clone -q "$_d/origin.git" "$_d/upstream" || return 1
  printf '%s\n' feature >> "$_d/upstream/file.txt" || return 1
  if [ -n "${2:-}" ]; then
    printf '%s\n' "$2" >> "$_d/upstream/file.txt" || return 1
  fi
  git_c "$_d/upstream" commit -q -a -m "squash feature" || return 1
  git_c "$_d/upstream" push -q origin main || return 1
  FX_S=$(git -C "$_d/upstream" rev-parse HEAD) || return 1
}

# new_case <name> [squash extra line]: a fresh fixture under TEST_TMP/<name>. Sets S7, the short squash sha.
new_case() {
  make_fixture "$TEST_TMP/$1" "${2:-}" || exit 2
  S7=$(short7 "$FX_S") || exit 2
  write_merge MERGED "$FX_S" || exit 2
}

# make_local_commit: one commit on the runner branch that is not pushed, so the local tip differs from origin.
make_local_commit() {
  printf '%s\n' 'local only' >> "$FX_WT/file.txt" || return 1
  git_c "$FX_WT" commit -q -a -m 'local only' || return 1
}

# add_child <path>: a detached child worktree at main with plan.md untracked.
add_child() {
  git_c "$FX_ROOT" worktree add -q --detach "$1" main || return 1
  printf '%s\n' plan > "$1/plan.md" || return 1
}

# add_reconcile: the reconcile worktree at the origin branch tip with plan.md untracked.
add_reconcile() {
  git_c "$FX_ROOT" worktree add -q --detach "$FX_ROOT/.worktrees/$FX_RECON" "origin/$FX_BRANCH" || return 1
  printf '%s\n' plan > "$FX_ROOT/.worktrees/$FX_RECON/plan.md" || return 1
}

# run_close [args]: run the script with the arguments and no stdin. Sets RC, leaves stdout in
# $TEST_TMP/out and stderr in $TEST_TMP/err.
run_close() {
  sh "$SCRIPT" "$@" >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
  RC=$?
}

# std_run [extra args]: the standard options for PR 431 on the fixture plus the extra arguments.
std_run() {
  run_close -r "$FX_ROOT" -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX" "$@"
}

# want <name> <line>...: write the expected stdout lines to $TEST_TMP/want-<name>.
want() {
  _wn=$1
  shift
  printf '%s\n' "$@" > "$TEST_TMP/want-$_wn" || exit 2
}

# want_green <name> <worktree line>...: the expected stdout when the merged, NOTE, ancestry and patch lines
# are all OK for the current fixture, followed by the given worktree lines.
want_green() {
  _gn=$1
  shift
  want "$_gn" "OK merged: $FX_S" "$NOTE_FETCH" "OK ancestry: $S7 is in origin/main" "$PATCH_OK" "$@"
}

# assert_case <name> <expected exit> <want name>: the exit code and the exact stdout lines.
assert_case() {
  assert_exit "$1 exit" "$2" "$RC"
  assert_file_eq "$1 lines" "$TEST_TMP/want-$3" "$TEST_TMP/out"
}

# usage_case <name> [args]: a usage error exits 2, prints nothing on stdout and a usage message on stderr.
usage_case() {
  _un=$1
  shift
  run_close "$@"
  assert_exit "usage-$_un exit" 2 "$RC"
  assert_empty "usage-$_un stdout" "$TEST_TMP/out"
  assert_nonempty "usage-$_un stderr" "$TEST_TMP/err"
  assert_grep "usage-$_un message" 'usage' "$TEST_TMP/err"
}

# snapshot <file>: the refs, the worktree list, the file list under .worktrees and the status of each worktree.
snapshot() {
  {
    git -C "$FX_ROOT" for-each-ref
    git -C "$FX_ROOT" worktree list --porcelain
    find "$FX_ROOT/.worktrees" -name .git -prune -o -print | sort
    for _sw in "$FX_ROOT"/.worktrees/*; do
      printf '%s\n' "$_sw"
      git -C "$_sw" status --short --ignored
    done
  } > "$1" || exit 2
}

# Case 1: all OK on the runner worktree alone. plan.md is the only untracked file and the patch is equal.
new_case all-ok
want_green all-ok "OK worktree: $FX_WT clean"
std_run
assert_case all-ok 0 all-ok

# Case 2: two child worktrees, each with plan.md untracked. Three worktree lines in path order.
new_case two-children
add_child "$FX_ROOT/.worktrees/$FX_PREFIX-a" || exit 2
add_child "$FX_ROOT/.worktrees/$FX_PREFIX-b" || exit 2
want_green two-children \
  "OK worktree: $FX_WT clean" \
  "OK worktree: $FX_ROOT/.worktrees/$FX_PREFIX-a clean" \
  "OK worktree: $FX_ROOT/.worktrees/$FX_PREFIX-b clean"
std_run
assert_case two-children 0 two-children

# Case 3: the squash holds one extra line, so the patch differs. Only the patch line fails.
new_case patch-differs extra
want patch-differs "OK merged: $FX_S" "$NOTE_FETCH" "OK ancestry: $S7 is in origin/main" \
  "FAIL patch: squash differs from branch diff" "OK worktree: $FX_WT clean"
std_run
assert_case patch-differs 1 patch-differs

# Case 4: a modified tracked file in the runner worktree fails the worktree line with its status.
new_case dirty-tracked
printf '%s\n' more >> "$FX_WT/file.txt" || exit 2
want_green dirty-tracked "FAIL worktree: $FX_WT has  M file.txt, ?? plan.md"
std_run
assert_case dirty-tracked 1 dirty-tracked

# Case 5: an untracked file other than the plan file fails the worktree line.
new_case untracked-other
printf '%s\n' scratch > "$FX_WT/scratch.txt" || exit 2
want_green untracked-other "FAIL worktree: $FX_WT has ?? plan.md, ?? scratch.txt"
std_run
assert_case untracked-other 1 untracked-other

# Case 6: an ignored file (matched by the committed .gitignore) fails the worktree line.
new_case ignored-file
printf '%s\n' log > "$FX_WT/ignored.log" || exit 2
want_green ignored-file "FAIL worktree: $FX_WT has ?? plan.md, !! ignored.log"
std_run
assert_case ignored-file 1 ignored-file

# Case 7: a dirty child fails only its own line; the runner and the clean sibling stay OK.
new_case dirty-child
add_child "$FX_ROOT/.worktrees/$FX_PREFIX-a" || exit 2
add_child "$FX_ROOT/.worktrees/$FX_PREFIX-b" || exit 2
printf '%s\n' scratch > "$FX_ROOT/.worktrees/$FX_PREFIX-b/scratch.txt" || exit 2
want_green dirty-child \
  "OK worktree: $FX_WT clean" \
  "OK worktree: $FX_ROOT/.worktrees/$FX_PREFIX-a clean" \
  "FAIL worktree: $FX_ROOT/.worktrees/$FX_PREFIX-b has ?? plan.md, ?? scratch.txt"
std_run
assert_case dirty-child 1 dirty-child

# Case 8: the runner worktree is removed while the local branch stays. The worktree line is OK absent.
new_case runner-absent
git_c "$FX_ROOT" worktree remove --force "$FX_WT" || exit 2
want_green runner-absent "OK worktree: $FX_WT absent"
std_run
assert_case runner-absent 0 runner-absent

# Case 9: the runner worktree and the local branch are both gone. The patch cannot find the branch tip.
new_case branch-tip-missing
git_c "$FX_ROOT" worktree remove --force "$FX_WT" || exit 2
git -C "$FX_ROOT" branch -q -D "$FX_BRANCH" || exit 2
want branch-tip-missing "OK merged: $FX_S" "$NOTE_FETCH" "OK ancestry: $S7 is in origin/main" \
  "FAIL patch: branch tip not found" "OK worktree: $FX_WT absent"
std_run
assert_case branch-tip-missing 1 branch-tip-missing

# Case 10: state OPEN with a null merge commit. The state line wins; the others name the missing commit.
new_case state-open
write_merge OPEN null
want state-open "FAIL merged: state is OPEN" "$NOTE_FETCH" "FAIL ancestry: no merge commit" \
  "FAIL patch: no merge commit" "OK worktree: $FX_WT clean"
std_run
assert_case state-open 1 state-open

# Case 11: state MERGED with a null merge commit fails the merged line with no merge commit.
new_case merged-null
write_merge MERGED null
want merged-null "FAIL merged: no merge commit" "$NOTE_FETCH" "FAIL ancestry: no merge commit" \
  "FAIL patch: no merge commit" "OK worktree: $FX_WT clean"
std_run
assert_case merged-null 1 merged-null

# Case 12: the gh stub exits non-zero. The merged line says gh failed; the rest follow from no merge commit.
new_case gh-exit
write_merge MERGED "$FX_S"
want gh-exit "FAIL merged: gh failed" "$NOTE_FETCH" "FAIL ancestry: no merge commit" \
  "FAIL patch: no merge commit" "OK worktree: $FX_WT clean"
export STUB_EXIT=1
std_run
unset STUB_EXIT
assert_case gh-exit 1 gh-exit

# Case 13: the gh stub prints invalid JSON. The same lines as the non-zero exit.
new_case gh-invalid-json
printf '%s\n' 'not json at all' > "$TEST_TMP/bad.json" || exit 2
want gh-invalid-json "FAIL merged: gh failed" "$NOTE_FETCH" "FAIL ancestry: no merge commit" \
  "FAIL patch: no merge commit" "OK worktree: $FX_WT clean"
export STUB_JSON=$TEST_TMP/bad.json
std_run
export STUB_JSON=$JSON
assert_case gh-invalid-json 1 gh-invalid-json

# Case 14: the merge commit is not in origin/main (here the branch tip, which origin has only on its branch).
new_case not-in-origin
write_merge MERGED "$FX_H"
H7=$(short7 "$FX_H") || exit 2
want not-in-origin "OK merged: $FX_H" "$NOTE_FETCH" "FAIL ancestry: $H7 is not in origin/main" \
  "$PATCH_OK" "OK worktree: $FX_WT clean"
std_run
assert_case not-in-origin 1 not-in-origin

# Case 15: the origin path is removed, so the fetch fails. Ancestry and patch both say fetch failed.
new_case fetch-fails
write_merge MERGED "$FX_S"
rm -rf "$FX_ORIGIN" || exit 2
want fetch-fails "OK merged: $FX_S" "$NOTE_FETCH" "FAIL ancestry: fetch failed" \
  "FAIL patch: fetch failed" "OK worktree: $FX_WT clean"
std_run
assert_case fetch-fails 1 fetch-fails

# Case 16: the local branch tip has an unpushed commit and no -x. The patch uses the local tip and differs.
new_case local-tip-no-x
make_local_commit || exit 2
want local-tip-no-x "OK merged: $FX_S" "$NOTE_FETCH" "OK ancestry: $S7 is in origin/main" \
  "FAIL patch: squash differs from branch diff" "OK worktree: $FX_WT clean"
std_run
assert_case local-tip-no-x 1 local-tip-no-x

# Case 17: -x with an unpushed local commit and a reconcile worktree with a child. The patch uses origin's
# branch tip, not the unpushed local tip, so it is OK; all three worktree lines are clean.
new_case x-all-ok
make_local_commit || exit 2
add_reconcile || exit 2
add_child "$FX_ROOT/.worktrees/$FX_RECON-c" || exit 2
want_green x-all-ok \
  "OK worktree: $FX_WT clean" \
  "OK worktree: $FX_ROOT/.worktrees/$FX_RECON clean" \
  "OK worktree: $FX_ROOT/.worktrees/$FX_RECON-c clean"
std_run -x "$FX_RECON"
assert_case x-all-ok 0 x-all-ok

# Case 18: -x with a dirty reconcile worktree fails that worktree line only.
new_case x-dirty
make_local_commit || exit 2
add_reconcile || exit 2
printf '%s\n' scratch > "$FX_ROOT/.worktrees/$FX_RECON/scratch.txt" || exit 2
want_green x-dirty \
  "OK worktree: $FX_WT clean" \
  "FAIL worktree: $FX_ROOT/.worktrees/$FX_RECON has ?? plan.md, ?? scratch.txt"
std_run -x "$FX_RECON"
assert_case x-dirty 1 x-dirty

# Case 19: -x with no reconcile worktree. The reconcile path line is OK absent.
new_case x-absent
make_local_commit || exit 2
want_green x-absent "OK worktree: $FX_WT clean" "OK worktree: $FX_ROOT/.worktrees/$FX_RECON absent"
std_run -x "$FX_RECON"
assert_case x-absent 0 x-absent

# Case 20: -P notes.md with notes.md untracked and no plan.md. The worktree is clean.
new_case plan-name-ok
rm -f "$FX_WT/plan.md" || exit 2
printf '%s\n' notes > "$FX_WT/notes.md" || exit 2
want_green plan-name-ok "OK worktree: $FX_WT clean"
std_run -P notes.md
assert_case plan-name-ok 0 plan-name-ok

# Case 21: -P notes.md with plan.md untracked and no notes.md. plan.md is now an unexpected file.
new_case plan-name-fail
want_green plan-name-fail "FAIL worktree: $FX_WT has ?? plan.md"
std_run -P notes.md
assert_case plan-name-fail 1 plan-name-fail

# Case 22: the default plan file is absent, so the worktree status is empty. Nothing is unexpected: OK clean.
new_case no-plan-file
rm -f "$FX_WT/plan.md" || exit 2
want_green no-plan-file "OK worktree: $FX_WT clean"
std_run
assert_case no-plan-file 0 no-plan-file

# Case 23: a run leaves the repositories unchanged. The fetch is a no-op here (the root fetched first),
# so the refs, the worktree list, the worktree files and the worktree status must match before and after.
new_case unchanged
git -C "$FX_ROOT" fetch -q origin || exit 2
want_green unchanged "OK worktree: $FX_WT clean"
snapshot "$TEST_TMP/before" || exit 2
std_run
assert_case unchanged 0 unchanged
snapshot "$TEST_TMP/after" || exit 2
assert_file_eq "unchanged repositories" "$TEST_TMP/before" "$TEST_TMP/after"

# Cases 24-31: usage errors. Each missing required option, an unknown option and an option with no value.
new_case usage
usage_case missing-r -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX"
usage_case missing-n -r "$FX_ROOT" -b "$FX_BRANCH" -p "$FX_PREFIX"
usage_case missing-b -r "$FX_ROOT" -n 431 -p "$FX_PREFIX"
usage_case missing-p -r "$FX_ROOT" -n 431 -b "$FX_BRANCH"
usage_case unknown-option -r "$FX_ROOT" -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX" -z
usage_case value-r -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX" -r
usage_case value-x -r "$FX_ROOT" -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX" -x
usage_case value-P -r "$FX_ROOT" -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX" -P

# Case 32: origin/main has a second commit (later main) after the squash S. The runner merges S into its branch,
# so the branch tip H holds S and merge-base(origin/main, H) is S, while merge-base(S^, H) is S^. The squash and
# the branch diff from S^ are equal, so the patch is OK. A base taken from origin/main gives an empty diff and
# FAIL. The ancestry check is OK because S is a proper ancestor of origin/main.
new_case later-main
git_c "$FX_ROOT" fetch -q origin main || exit 2
git_c "$FX_WT" merge -q --no-edit "$FX_S" || exit 2
git_c "$FX_ROOT" push -q origin "$FX_BRANCH" || exit 2
printf '%s\n' later > "$TEST_TMP/later-main/upstream/other.txt" || exit 2
git_c "$TEST_TMP/later-main/upstream" add other.txt || exit 2
git_c "$TEST_TMP/later-main/upstream" commit -q -m "later main" || exit 2
git_c "$TEST_TMP/later-main/upstream" push -q origin main || exit 2
want_green later-main "OK worktree: $FX_WT clean"
std_run
assert_case later-main 0 later-main

test_summary
