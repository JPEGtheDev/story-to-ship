#!/bin/sh
# Fixture tests for closeout-check.sh (cases 1-39) and closeout-steps.sh (group 2): the merged, fetch NOTE,
# ancestry, patch and worktree lines, the -x and -P options, the gh failure paths, usage errors (exit 2),
# an unchanged-repositories check, the steps' removal, deletion, fast-forward and refusal paths, and the steps'
# issue, epic and flaky-run lines.
# No network: the gh command is a stub that prints a JSON fixture file, and every repository is a clone
# of a local bare origin under the test temp directory.
# CLOSEOUT_CHECK=<path> substitutes another script (used to prove a test can fail).
# shellcheck source=SCRIPTDIR/lib.sh
. "$(dirname "$0")/lib.sh"

# write_closeout_gh_stub <file>: a gh stand-in that dispatches on its arguments. "pr view" prints STUB_JSON
# (STUB_EXIT, when set, is its exit code). "issue view <n> --json state" prints $STUB_DIR/issue-<n>.json,
# "issue view <n> --json body" prints $STUB_DIR/epic-<n>.json and "run list ..." prints $STUB_DIR/runs.json.
# A read whose marker $STUB_DIR/fail-<key> exists exits 1; one whose $STUB_DIR/bad-<key> exists prints
# invalid JSON. The keys are issue, epic and flaky. Any other call exits 2.
# The single-quoted lines are stub source text, so their $ must stay unexpanded.
# shellcheck disable=SC2016
write_closeout_gh_stub() {
  printf '%s\n' '#!/bin/sh' \
    'if [ "$1 $2" = "pr view" ]; then' \
    '  if [ -n "${STUB_EXIT:-}" ]; then exit "$STUB_EXIT"; fi' \
    '  cat "$STUB_JSON"' \
    '  exit 0' \
    'fi' \
    'if [ "$1 $2" = "issue view" ]; then' \
    '  if [ "$5" = state ]; then _k=issue; else _k=epic; fi' \
    '  _f="$STUB_DIR/$_k-$3.json"' \
    'elif [ "$1 $2" = "run list" ]; then' \
    '  _k=flaky' \
    '  _f="$STUB_DIR/runs.json"' \
    'else' \
    '  printf "%s\n" "unexpected gh call: $*" >&2' \
    '  exit 2' \
    'fi' \
    'if [ -f "$STUB_DIR/fail-$_k" ]; then exit 1; fi' \
    'if [ -f "$STUB_DIR/bad-$_k" ]; then printf "%s\n" "not json"; exit 0; fi' \
    'cat "$_f"' > "$1" || return 1
  chmod +x "$1" || return 1
}

SCRIPT=${CLOSEOUT_CHECK:-$(dirname "$0")/../closeout-check.sh}
STUB=$TEST_TMP/gh-stub
JSON=$TEST_TMP/merge.json
export CLOSEOUT_GH="$STUB" STUB_JSON="$JSON" STUB_DIR="$TEST_TMP"
unset STUB_EXIT
write_closeout_gh_stub "$STUB" || exit 2

FX_PREFIX=example-tw
FX_BRANCH=agent/example-tw
FX_RECON=example-rc

# NOTE_FETCH: the fetch line printed after the merged line in every run, for the fixture branch.
NOTE_FETCH="NOTE fetch: ran git fetch origin main $FX_BRANCH"
# NOTE_GONE: the fetch line when the branch is not on origin (the host deleted it), so only main was fetched.
NOTE_GONE="NOTE fetch: ran git fetch origin main; $FX_BRANCH is not on origin"
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
# .gitignore that ignores *.log), a root clone at <dir>/root on main, the branch agent/example-tw with one
# commit in the runner worktree at <dir>/root/.worktrees/example-tw (plan.md untracked there), the branch
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

# write_issue <number> <state>: the gh issue view document for the state read (issue-<number>.json).
write_issue() {
  printf '{"state":"%s"}\n' "$2" > "$TEST_TMP/issue-$1.json" || exit 2
}

# write_epic <number> <body line>...: the gh issue view document for the body read (epic-<number>.json), with
# the lines joined by newlines as the body string.
write_epic() {
  _we=$1
  shift
  printf '%s\n' "$@" | jq -Rs '{body: .}' > "$TEST_TMP/epic-$_we.json" || exit 2
}

# write_runs <JSON array>: the gh run list document for the flaky read (runs.json).
write_runs() {
  printf '%s\n' "$1" > "$TEST_TMP/runs.json" || exit 2
}

# gh_reset: the gh reads of a fresh case: issue 427 CLOSED, no runs, no epic document, and no failure or bad
# markers. A case that needs another read value writes it after new_case.
gh_reset() {
  write_issue 427 CLOSED
  write_runs '[]'
  rm -f "$TEST_TMP"/fail-* "$TEST_TMP"/bad-* "$TEST_TMP"/epic-*.json || exit 2
}

# new_case <name> [squash extra line]: a fresh fixture under TEST_TMP/<name>. Sets S7, the short squash sha.
new_case() {
  make_fixture "$TEST_TMP/$1" "${2:-}" || exit 2
  S7=$(short7 "$FX_S") || exit 2
  write_merge MERGED "$FX_S" || exit 2
  gh_reset
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

# usage_expect <label> <runner function> [args]: the runner exits 2, prints nothing on stdout and a usage
# message on stderr.
usage_expect() {
  _ul=$1
  _ur=$2
  shift 2
  "$_ur" "$@"
  assert_exit "$_ul exit" 2 "$RC"
  assert_empty "$_ul stdout" "$TEST_TMP/out"
  assert_nonempty "$_ul stderr" "$TEST_TMP/err"
  assert_grep "$_ul message" 'usage' "$TEST_TMP/err"
}

# usage_case <name> [args]: usage_expect for closeout-check.sh.
usage_case() {
  _un=$1
  shift
  usage_expect "usage-$_un" run_close "$@"
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
export STUB_JSON="$TEST_TMP/bad.json"
std_run
export STUB_JSON="$JSON"
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

# Case 33: the host deleted the branch on origin, the local branch and the runner worktree remain. The branch is
# not fetched, the NOTE says so, and the local tip still matches the squash, so every line is OK.
new_case origin-gone-local-kept
git -C "$FX_ORIGIN" update-ref -d "refs/heads/$FX_BRANCH" || exit 2
want origin-gone-local-kept "OK merged: $FX_S" "$NOTE_GONE" "OK ancestry: $S7 is in origin/main" \
  "$PATCH_OK" "OK worktree: $FX_WT clean"
std_run
assert_case origin-gone-local-kept 0 origin-gone-local-kept

# Case 34: the branch is gone from origin and the local branch (with its runner worktree) is gone too. No tip exists,
# so the patch line says branch tip not found; ancestry is still OK.
new_case origin-gone-local-gone
git -C "$FX_ORIGIN" update-ref -d "refs/heads/$FX_BRANCH" || exit 2
git_c "$FX_ROOT" worktree remove --force "$FX_WT" || exit 2
git_c "$FX_ROOT" branch -q -D "$FX_BRANCH" || exit 2
want origin-gone-local-gone "OK merged: $FX_S" "$NOTE_GONE" "OK ancestry: $S7 is in origin/main" \
  "FAIL patch: branch tip not found" "OK worktree: $FX_WT absent"
std_run
assert_case origin-gone-local-gone 1 origin-gone-local-gone

# Case 35: the branch is gone from origin and -x is given, so the patch tip is origin/<branch>. The stale
# remote-tracking ref is removed here, as a prune would remove it, so the tip is not found; ancestry is OK.
new_case origin-gone-x
git -C "$FX_ORIGIN" update-ref -d "refs/heads/$FX_BRANCH" || exit 2
git_c "$FX_ROOT" update-ref -d "refs/remotes/origin/$FX_BRANCH" || exit 2
want origin-gone-x "OK merged: $FX_S" "$NOTE_GONE" "OK ancestry: $S7 is in origin/main" \
  "FAIL patch: branch tip not found" "OK worktree: $FX_WT clean" \
  "OK worktree: $FX_ROOT/.worktrees/$FX_RECON absent"
std_run -x "$FX_RECON"
assert_case origin-gone-x 1 origin-gone-x

# Case 36: origin still has the branch, but its main ref is gone, so the main fetch fails while the branch probe
# succeeds. The fetch failure is reported as before: ancestry and patch both say fetch failed.
new_case main-gone-on-origin
git -C "$FX_ORIGIN" update-ref -d refs/heads/main || exit 2
want main-gone-on-origin "OK merged: $FX_S" "$NOTE_FETCH" "FAIL ancestry: fetch failed" \
  "FAIL patch: fetch failed" "OK worktree: $FX_WT clean"
std_run
assert_case main-gone-on-origin 1 main-gone-on-origin

# Case 37: the branch was pushed to origin after the root clone, so the root has no origin/<branch> ref (simulated
# by deleting it). With -x the patch tip is origin/<branch>, so the branch fetch is needed; it succeeds and every
# line is OK.
new_case branch-fetch-needed
git_c "$FX_ROOT" update-ref -d "refs/remotes/origin/$FX_BRANCH" || exit 2
want branch-fetch-needed "OK merged: $FX_S" "$NOTE_FETCH" "OK ancestry: $S7 is in origin/main" "$PATCH_OK" \
  "OK worktree: $FX_WT clean" "OK worktree: $FX_ROOT/.worktrees/$FX_RECON absent"
std_run -x "$FX_RECON"
assert_case branch-fetch-needed 0 branch-fetch-needed

# Case 38: origin lists the branch, but its tip commit object is missing from origin, so the branch fetch fails
# while the probe says the branch is present. The tip is a new commit pushed from a clone (the root never has it)
# and its loose object is then removed from the bare origin. Ancestry and patch both say fetch failed.
new_case branch-fetch-fails
git clone -q "$FX_ORIGIN" "$TEST_TMP/branch-fetch-fails-up" || exit 2
git_c "$TEST_TMP/branch-fetch-fails-up" checkout -q -b "$FX_BRANCH" "origin/$FX_BRANCH" || exit 2
printf '%s\n' later >> "$TEST_TMP/branch-fetch-fails-up/file.txt" || exit 2
git_c "$TEST_TMP/branch-fetch-fails-up" commit -q -a -m later || exit 2
git_c "$TEST_TMP/branch-fetch-fails-up" push -q origin "HEAD:refs/heads/$FX_BRANCH" || exit 2
_bf_sha=$(git -C "$TEST_TMP/branch-fetch-fails-up" rev-parse HEAD) || exit 2
_bf_obj="$FX_ORIGIN/objects/$(printf '%s\n' "$_bf_sha" | sed 's/^\(..\)/\1\//')"
[ -f "$_bf_obj" ] || exit 2
rm "$_bf_obj" || exit 2
want branch-fetch-fails "OK merged: $FX_S" "$NOTE_FETCH" "FAIL ancestry: fetch failed" \
  "FAIL patch: fetch failed" "OK worktree: $FX_WT clean"
std_run
assert_case branch-fetch-fails 1 branch-fetch-fails

# Case 39: origin has a branch y/<branch> and no branch <branch>, and the local branch is present with an equal
# patch. The probe must match the exact ref, so the branch is not on origin: the NOTE says so and every line is OK.
new_case origin-prefixed-branch
git -C "$FX_ORIGIN" update-ref "refs/heads/y/$FX_BRANCH" "$FX_H" || exit 2
git -C "$FX_ORIGIN" update-ref -d "refs/heads/$FX_BRANCH" || exit 2
want origin-prefixed-branch "OK merged: $FX_S" "$NOTE_GONE" "OK ancestry: $S7 is in origin/main" "$PATCH_OK" \
  "OK worktree: $FX_WT clean"
std_run
assert_case origin-prefixed-branch 0 origin-prefixed-branch

# Group 2: closeout-steps.sh. CLOSEOUT_STEPS=<path> substitutes another steps script. The steps script runs
# closeout-check.sh next to itself unless CLOSEOUT_CHECK names another check; the cases marked stub name a stub
# that prints one OK line.
STEPS=${CLOSEOUT_STEPS:-$(dirname "$0")/../closeout-steps.sh}
STUBCHK=$TEST_TMP/check-stub
printf '%s\n' '#!/bin/sh' 'echo "OK check: stub"' 'exit 0' > "$STUBCHK" || exit 2
chmod +x "$STUBCHK" || exit 2
ZERO_SHA=0000000000000000000000000000000000000000

# run_steps [args]: run the steps script with the arguments and no stdin. Sets RC; stdout goes to
# $TEST_TMP/out and stderr to $TEST_TMP/err.
run_steps() {
  sh "$STEPS" "$@" >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
  RC=$?
}

# steps_std [extra args]: the steps options for PR 431 on the fixture with issue 427, plus the extra arguments.
steps_std() {
  run_steps -r "$FX_ROOT" -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX" -i 427 "$@"
}

# steps_stub: the standard steps options with CLOSEOUT_CHECK naming the stub check, so the check always passes.
steps_stub() {
  CLOSEOUT_CHECK=$STUBCHK sh "$STEPS" -r "$FX_ROOT" -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX" -i 427 \
    >"$TEST_TMP/out" 2>"$TEST_TMP/err" </dev/null
  RC=$?
}

# steps_usage_case <name> [args]: usage_expect for closeout-steps.sh.
steps_usage_case() {
  _un=$1
  shift
  usage_expect "steps-usage-$_un" run_steps "$@"
}

# steps_prefetch: fetch the root's remote refs first, so the check's own fetch changes no ref in the snapshots.
steps_prefetch() {
  git_c "$FX_ROOT" fetch -q origin || exit 2
}

# steps_snapshot <file>: the root HEAD, the root and origin refs, the worktree list, the root status, every file
# under the root except .git with its content, and the status of each worktree under .worktrees.
steps_snapshot() {
  {
    git -C "$FX_ROOT" symbolic-ref HEAD
    git -C "$FX_ROOT" for-each-ref
    git -C "$FX_ORIGIN" for-each-ref
    git -C "$FX_ROOT" worktree list --porcelain
    git -C "$FX_ROOT" status --short --ignored
    find "$FX_ROOT" -name .git -prune -o -type f -print | LC_ALL=C sort | while IFS= read -r _sf; do
      printf 'file %s\n' "$_sf"
      cat "$_sf"
    done
    find "$FX_ROOT/.worktrees" -mindepth 1 -maxdepth 1 -type d | LC_ALL=C sort | while IFS= read -r _sw; do
      printf 'status %s\n' "$_sw"
      git -C "$_sw" status --short --ignored
    done
  } > "$1" || exit 2
}

# steps_compare <name> <before file>: take the snapshot now and assert it equals the before snapshot.
steps_compare() {
  steps_snapshot "$TEST_TMP/after-$1" || exit 2
  assert_file_eq "$1 unchanged" "$2" "$TEST_TMP/after-$1"
}

# normalize_step_fail <step name> <actual file> <out file>: rewrite the FAIL line of the named step to
# `FAIL <step name>: <git error>` when its message after the prefix is non-empty. git words its own error
# text differently by version, so only the presence of that text is checked. An empty message is left as it
# is and fails the byte comparison that follows.
normalize_step_fail() {
  sed "s/^FAIL $1: .\{1,\}\$/FAIL $1: <git error>/" "$2" > "$3" || exit 2
}

# assert_case_step <name> <expected exit> <want name> <step name>: assert_case after normalize_step_fail on the
# actual stdout of the named step.
assert_case_step() {
  normalize_step_fail "$4" "$TEST_TMP/out" "$TEST_TMP/norm-$1" || exit 2
  assert_exit "$1 exit" "$2" "$RC"
  assert_file_eq "$1 lines" "$TEST_TMP/want-$3" "$TEST_TMP/norm-$1"
}

# refs_actual <file>: the local and origin branch refs, the root main sha and the registered worktrees.
refs_actual() {
  {
    git -C "$FX_ROOT" for-each-ref --format='local %(refname)' refs/heads
    git -C "$FX_ORIGIN" for-each-ref --format='origin %(refname)' refs/heads
    git -C "$FX_ROOT" rev-parse refs/heads/main | sed 's/^/main /'
    git -C "$FX_ROOT" worktree list --porcelain | grep '^worktree ' | LC_ALL=C sort
  } > "$1" || exit 2
}

# refs_want <file> <local branch 0|1> <origin branch 0|1> <main sha> <runner worktree 0|1>: the expected
# refs_actual lines for the fixture, the root worktree and the runner worktree when it is present.
refs_want() {
  {
    if [ "$2" = 1 ]; then
      printf 'local refs/heads/%s\n' "$FX_BRANCH"
    fi
    printf 'local refs/heads/main\n'
    if [ "$3" = 1 ]; then
      printf 'origin refs/heads/%s\n' "$FX_BRANCH"
    fi
    printf 'origin refs/heads/main\n'
    printf 'main %s\n' "$4"
    printf 'worktree %s\n' "$FX_ROOT"
    if [ "$5" = 1 ]; then
      printf 'worktree %s\n' "$FX_WT"
    fi
  } > "$1" || exit 2
}

# assert_refs <name> <local branch 0|1> <origin branch 0|1> <main sha> <runner worktree 0|1>: after a run, the refs
# and worktrees equal refs_want for those arguments.
assert_refs() {
  refs_want "$TEST_TMP/want-refs-$1" "$2" "$3" "$4" "$5"
  refs_actual "$TEST_TMP/got-refs-$1"
  assert_file_eq "$1 refs" "$TEST_TMP/want-refs-$1" "$TEST_TMP/got-refs-$1"
}

# check_alone <name>: run closeout-check.sh alone on the fixture with the standard options and keep its output.
check_alone() {
  std_run
  cp "$TEST_TMP/out" "$TEST_TMP/check-alone-$1" || exit 2
}

# check_prefix_eq <name>: the first lines of the steps output are exactly the lines check_alone kept.
check_prefix_eq() {
  _cn=$(wc -l < "$TEST_TMP/check-alone-$1" | tr -d ' ') || exit 2
  sed -n "1,${_cn}p" "$TEST_TMP/out" > "$TEST_TMP/prefix-$1" || exit 2
  assert_file_eq "$1 check lines first" "$TEST_TMP/check-alone-$1" "$TEST_TMP/prefix-$1"
}

# Step case 1: a clean runner worktree and two clean children. Every worktree is removed, the branch is deleted
# locally and on origin, main moves to origin/main, and the check lines are those closeout-check.sh prints alone.
new_case steps-all
add_child "$FX_ROOT/.worktrees/$FX_PREFIX-a" || exit 2
add_child "$FX_ROOT/.worktrees/$FX_PREFIX-b" || exit 2
check_alone steps-all
want steps-all \
  "OK merged: $FX_S" "$NOTE_FETCH" "OK ancestry: $S7 is in origin/main" "$PATCH_OK" \
  "OK worktree: $FX_WT clean" \
  "OK worktree: $FX_ROOT/.worktrees/$FX_PREFIX-a clean" \
  "OK worktree: $FX_ROOT/.worktrees/$FX_PREFIX-b clean" \
  "OK remove-worktree: $FX_WT" \
  "OK remove-worktree: $FX_ROOT/.worktrees/$FX_PREFIX-a" \
  "OK remove-worktree: $FX_ROOT/.worktrees/$FX_PREFIX-b" \
  "OK delete-branch-local: $FX_BRANCH" \
  "OK delete-branch-origin: $FX_BRANCH" \
  "OK fast-forward: main at $S7" \
  "OK issue: #427 CLOSED" \
  "OK flaky: 0"
steps_std
assert_case steps-all 0 steps-all
check_prefix_eq steps-all
assert_refs steps-all 0 0 "$FX_S" 0

# Step case 2: -e 400 names an epic whose body has an unchecked line for #427. One clean runner worktree, otherwise
# as case 1; the epic line follows the issue line.
new_case steps-epic
write_epic 400 "- [ ] #427 the story"
want_green steps-epic "OK worktree: $FX_WT clean" "OK remove-worktree: $FX_WT" \
  "OK delete-branch-local: $FX_BRANCH" "OK delete-branch-origin: $FX_BRANCH" "OK fast-forward: main at $S7" \
  "OK issue: #427 CLOSED" "OK epic: #400 [ ] #427" "OK flaky: 0"
steps_std -e 400
assert_case steps-epic 0 steps-epic

# Step case 3: a child holds an untracked scratch file. The check fails, so nothing is removed or deleted.
new_case steps-dirty-child
add_child "$FX_ROOT/.worktrees/$FX_PREFIX-a" || exit 2
add_child "$FX_ROOT/.worktrees/$FX_PREFIX-b" || exit 2
printf '%s\n' scratch > "$FX_ROOT/.worktrees/$FX_PREFIX-b/scratch.txt" || exit 2
steps_prefetch
check_alone steps-dirty-child
want_green steps-dirty-child \
  "OK worktree: $FX_WT clean" \
  "OK worktree: $FX_ROOT/.worktrees/$FX_PREFIX-a clean" \
  "FAIL worktree: $FX_ROOT/.worktrees/$FX_PREFIX-b has ?? plan.md, ?? scratch.txt" \
  "FAIL steps: refused, close-out check failed"
steps_snapshot "$TEST_TMP/before-steps-dirty-child" || exit 2
steps_std
assert_case steps-dirty-child 1 steps-dirty-child
check_prefix_eq steps-dirty-child
steps_compare steps-dirty-child "$TEST_TMP/before-steps-dirty-child"

# Step case 4: the PR is OPEN. The check fails on the state and the missing merge commit, so the run is refused.
new_case steps-open
write_merge OPEN null
steps_prefetch
check_alone steps-open
want steps-open "FAIL merged: state is OPEN" "$NOTE_FETCH" "FAIL ancestry: no merge commit" \
  "FAIL patch: no merge commit" "OK worktree: $FX_WT clean" "FAIL steps: refused, close-out check failed"
steps_snapshot "$TEST_TMP/before-steps-open" || exit 2
steps_std
assert_case steps-open 1 steps-open
check_prefix_eq steps-open
steps_compare steps-open "$TEST_TMP/before-steps-open"

# Step case 5: the check passes, but the repo root is on side, not main. The run is refused before any step.
new_case steps-root-branch
git_c "$FX_ROOT" checkout -q -b side || exit 2
steps_prefetch
check_alone steps-root-branch
want_green steps-root-branch "OK worktree: $FX_WT clean" "FAIL steps: refused, repo root is on side, not main"
steps_snapshot "$TEST_TMP/before-steps-root-branch" || exit 2
steps_std
assert_case steps-root-branch 1 steps-root-branch
check_prefix_eq steps-root-branch
steps_compare steps-root-branch "$TEST_TMP/before-steps-root-branch"

# Step case 6: a second run on the fully closed-out state. The branch is gone from origin and locally, so the check
# does not fetch it (NOTE says so), ancestry is OK and the patch finds no branch tip; the run is refused and
# changes nothing.
new_case steps-second-run
steps_prefetch
steps_std
assert_exit "steps-second-run first exit" 0 "$RC"
want steps-second-run "OK merged: $FX_S" "$NOTE_GONE" "OK ancestry: $S7 is in origin/main" \
  "FAIL patch: branch tip not found" "OK worktree: $FX_WT absent" "FAIL steps: refused, close-out check failed"
steps_snapshot "$TEST_TMP/before-steps-second-run" || exit 2
steps_std
assert_case steps-second-run 1 steps-second-run
steps_compare steps-second-run "$TEST_TMP/before-steps-second-run"

# Step case 7: with -x, the runner worktree and its branch are already gone. The check uses origin's branch tip,
# so it passes; the absent lines and the already gone line are printed and the rest runs.
new_case steps-x-local-gone
git_c "$FX_ROOT" worktree remove --force "$FX_WT" || exit 2
git_c "$FX_ROOT" branch -q -D "$FX_BRANCH" || exit 2
want steps-x-local-gone "OK merged: $FX_S" "$NOTE_FETCH" "OK ancestry: $S7 is in origin/main" "$PATCH_OK" \
  "OK worktree: $FX_WT absent" "OK worktree: $FX_ROOT/.worktrees/$FX_RECON absent" \
  "OK remove-worktree: $FX_WT absent" "OK remove-worktree: $FX_ROOT/.worktrees/$FX_RECON absent" \
  "OK delete-branch-local: $FX_BRANCH already gone" "OK delete-branch-local: reconcile-$FX_RECON already gone" \
  "OK delete-branch-origin: $FX_BRANCH" "OK fast-forward: main at $S7" "OK issue: #427 CLOSED" "OK flaky: 0"
steps_std -x "$FX_RECON"
assert_case steps-x-local-gone 0 steps-x-local-gone
assert_refs steps-x-local-gone 0 0 "$FX_S" 0

# Step case 8: with -x, a reconcile worktree on its own local branch and a reconcile child. The reconcile worktree,
# its child and the reconcile branch are removed after the runner side, then the branch on origin, then main.
new_case steps-x-full
git_c "$FX_ROOT" worktree add -q -b "reconcile-$FX_RECON" "$FX_ROOT/.worktrees/$FX_RECON" "origin/$FX_BRANCH" || exit 2
printf '%s\n' plan > "$FX_ROOT/.worktrees/$FX_RECON/plan.md" || exit 2
add_child "$FX_ROOT/.worktrees/$FX_RECON-c" || exit 2
want steps-x-full "OK merged: $FX_S" "$NOTE_FETCH" "OK ancestry: $S7 is in origin/main" "$PATCH_OK" \
  "OK worktree: $FX_WT clean" \
  "OK worktree: $FX_ROOT/.worktrees/$FX_RECON clean" \
  "OK worktree: $FX_ROOT/.worktrees/$FX_RECON-c clean" \
  "OK remove-worktree: $FX_WT" \
  "OK remove-worktree: $FX_ROOT/.worktrees/$FX_RECON" \
  "OK remove-worktree: $FX_ROOT/.worktrees/$FX_RECON-c" \
  "OK delete-branch-local: $FX_BRANCH" \
  "OK delete-branch-local: reconcile-$FX_RECON" \
  "OK delete-branch-origin: $FX_BRANCH" \
  "OK fast-forward: main at $S7" \
  "OK issue: #427 CLOSED" \
  "OK flaky: 0"
steps_std -x "$FX_RECON"
assert_case steps-x-full 0 steps-x-full
assert_refs steps-x-full 0 0 "$FX_S" 0

# Step case 9 (stub check): the branch is already gone from origin. The check is the stub, so the steps alone decide.
new_case steps-origin-gone
steps_prefetch
git_c "$FX_ROOT" push -q origin --delete "$FX_BRANCH" >/dev/null 2>&1 || exit 2
want steps-origin-gone "OK check: stub" "OK remove-worktree: $FX_WT" "OK delete-branch-local: $FX_BRANCH" \
  "OK delete-branch-origin: $FX_BRANCH already gone" "OK fast-forward: main at $S7" \
  "OK issue: #427 CLOSED" "OK flaky: 0"
steps_stub
assert_case steps-origin-gone 0 steps-origin-gone
assert_refs steps-origin-gone 0 0 "$FX_S" 0

# Step case 10 (stub check): a re-run after a partial run. The worktree, the local branch and the origin branch are
# all gone; the absent and already gone lines are printed and the fast-forward is still done.
new_case steps-rerun
steps_prefetch
git_c "$FX_ROOT" worktree remove --force "$FX_WT" || exit 2
git_c "$FX_ROOT" branch -q -D "$FX_BRANCH" || exit 2
git_c "$FX_ROOT" push -q origin --delete "$FX_BRANCH" >/dev/null 2>&1 || exit 2
want steps-rerun "OK check: stub" "OK remove-worktree: $FX_WT absent" \
  "OK delete-branch-local: $FX_BRANCH already gone" "OK delete-branch-origin: $FX_BRANCH already gone" \
  "OK fast-forward: main at $S7" "OK issue: #427 CLOSED" "OK flaky: 0"
steps_stub
assert_case steps-rerun 0 steps-rerun
assert_refs steps-rerun 0 0 "$FX_S" 0

# Step case 11: the runner worktree is locked, so its removal fails first. Nothing has changed and the run stops.
new_case steps-remove-fails
git_c "$FX_ROOT" worktree lock "$FX_WT" || exit 2
steps_prefetch
want_green steps-remove-fails "OK worktree: $FX_WT clean" \
  "FAIL remove-worktree: <git error>" "FAIL steps: stopped, later steps not run"
steps_snapshot "$TEST_TMP/before-steps-remove-fails" || exit 2
steps_std
assert_case_step steps-remove-fails 1 steps-remove-fails remove-worktree
steps_compare steps-remove-fails "$TEST_TMP/before-steps-remove-fails"

# Step case 12: a second worktree holds the branch, so the worktree is removed and the local branch delete fails.
new_case steps-local-fails
steps_prefetch
git_c "$FX_ROOT" worktree add -q -f "$FX_ROOT/held" "$FX_BRANCH" || exit 2
want_green steps-local-fails "OK worktree: $FX_WT clean" "OK remove-worktree: $FX_WT" \
  "FAIL delete-branch-local: <git error>" "FAIL steps: stopped, later steps not run"
refs_want "$TEST_TMP/want-refs-steps-local-fails" 1 1 "$(git -C "$FX_ROOT" rev-parse refs/heads/main)" 0
printf 'worktree %s\n' "$FX_ROOT/held" >> "$TEST_TMP/want-refs-steps-local-fails"
steps_std
assert_case_step steps-local-fails 1 steps-local-fails delete-branch-local
refs_actual "$TEST_TMP/got-refs-steps-local-fails"
assert_file_eq "steps-local-fails refs" "$TEST_TMP/want-refs-steps-local-fails" "$TEST_TMP/got-refs-steps-local-fails"

# Step case 13: origin refuses ref deletions (a pre-receive hook in the bare origin). The worktree and the local
# branch are already removed; origin keeps its branch and main is not fast-forwarded.
new_case steps-origin-refuses
steps_prefetch
# shellcheck disable=SC2016 # the single-quoted lines are hook source text; their $ names expand when git runs the hook.
printf '%s\n' '#!/bin/sh' \
  'while read -r _old _new _ref; do' \
  '  if [ "$_new" = '"$ZERO_SHA"' ]; then' \
  '    exit 1' \
  '  fi' \
  'done' \
  'exit 0' > "$FX_ORIGIN/hooks/pre-receive" || exit 2
chmod +x "$FX_ORIGIN/hooks/pre-receive" || exit 2
_main0=$(git -C "$FX_ROOT" rev-parse refs/heads/main) || exit 2
want_green steps-origin-refuses "OK worktree: $FX_WT clean" "OK remove-worktree: $FX_WT" \
  "OK delete-branch-local: $FX_BRANCH" "FAIL delete-branch-origin: <git error>" \
  "FAIL steps: stopped, later steps not run"
steps_std
assert_case_step steps-origin-refuses 1 steps-origin-refuses delete-branch-origin
assert_refs steps-origin-refuses 0 1 "$_main0" 0

# Step case 14: root main has a commit that origin/main lacks, so the fast-forward fails after the deletions.
new_case steps-ff-fails
git_c "$FX_ROOT" commit -q --allow-empty -m "local main commit" || exit 2
steps_prefetch
_main0=$(git -C "$FX_ROOT" rev-parse refs/heads/main) || exit 2
want_green steps-ff-fails "OK worktree: $FX_WT clean" "OK remove-worktree: $FX_WT" \
  "OK delete-branch-local: $FX_BRANCH" "OK delete-branch-origin: $FX_BRANCH" \
  "FAIL fast-forward: <git error>" "FAIL steps: stopped, later steps not run"
steps_std
assert_case_step steps-ff-fails 1 steps-ff-fails fast-forward
assert_refs steps-ff-fails 0 0 "$_main0" 0

# Step case 15: the real check (no stub). The host deleted the branch on origin; the local branch and the runner
# worktree remain. The check passes with the not-on-origin NOTE, then every step runs and the branch is already gone.
new_case steps-origin-gone-real
steps_prefetch
git -C "$FX_ORIGIN" update-ref -d "refs/heads/$FX_BRANCH" || exit 2
want steps-origin-gone-real "OK merged: $FX_S" "$NOTE_GONE" "OK ancestry: $S7 is in origin/main" "$PATCH_OK" \
  "OK worktree: $FX_WT clean" "OK remove-worktree: $FX_WT" "OK delete-branch-local: $FX_BRANCH" \
  "OK delete-branch-origin: $FX_BRANCH already gone" "OK fast-forward: main at $S7" \
  "OK issue: #427 CLOSED" "OK flaky: 0"
steps_std
assert_case steps-origin-gone-real 0 steps-origin-gone-real
assert_refs steps-origin-gone-real 0 0 "$FX_S" 0

# Step case 16: the real check with origin holding y/<branch> and no <branch> (the same layout as check case 39).
# The check passes with the not-on-origin NOTE, the origin branch is already gone, and y/<branch> stays on origin.
new_case steps-origin-prefixed
git -C "$FX_ORIGIN" update-ref "refs/heads/y/$FX_BRANCH" "$FX_H" || exit 2
git -C "$FX_ORIGIN" update-ref -d "refs/heads/$FX_BRANCH" || exit 2
steps_prefetch
want steps-origin-prefixed "OK merged: $FX_S" "$NOTE_GONE" "OK ancestry: $S7 is in origin/main" "$PATCH_OK" \
  "OK worktree: $FX_WT clean" "OK remove-worktree: $FX_WT" "OK delete-branch-local: $FX_BRANCH" \
  "OK delete-branch-origin: $FX_BRANCH already gone" "OK fast-forward: main at $S7" \
  "OK issue: #427 CLOSED" "OK flaky: 0"
steps_std
assert_case steps-origin-prefixed 0 steps-origin-prefixed
_yk=0
git -C "$FX_ORIGIN" show-ref -q --verify "refs/heads/y/$FX_BRANCH" || _yk=$?
assert_exit "steps-origin-prefixed y branch kept on origin" 0 "$_yk"

# want_done <name> <line>...: the expected output of a close-out that completes on the fixture with only the runner
# worktree: the check lines, the four step lines, then the given lines.
want_done() {
  _dn=$1
  shift
  want_green "$_dn" "OK worktree: $FX_WT clean" "OK remove-worktree: $FX_WT" "OK delete-branch-local: $FX_BRANCH" \
    "OK delete-branch-origin: $FX_BRANCH" "OK fast-forward: main at $S7" "$@"
}

# steps_flaky_case <name> <run list JSON> <count>: a complete close-out with the given run list and no -e. The issue
# is CLOSED and the flaky line must print the count.
steps_flaky_case() {
  new_case "$1"
  write_runs "$2"
  want_done "$1" "OK issue: #427 CLOSED" "OK flaky: $3"
  steps_std
  assert_case "$1" 0 "$1"
}

# Issue state: an OPEN issue prints its state as the document says; the run still completes with exit 0.
new_case steps-issue-open
write_issue 427 OPEN
want_done steps-issue-open "OK issue: #427 OPEN" "OK flaky: 0"
steps_std
assert_case steps-issue-open 0 steps-issue-open
assert_refs steps-issue-open 0 0 "$FX_S" 0

# Epic line: a checked line for #427 prints [x].
new_case steps-epic-checked
write_epic 400 "- [x] #427 something"
want_done steps-epic-checked "OK issue: #427 CLOSED" "OK epic: #400 [x] #427" "OK flaky: 0"
steps_std -e 400
assert_case steps-epic-checked 0 steps-epic-checked

# Epic line: an upper-case X marker prints [x] too.
new_case steps-epic-upper
write_epic 400 "- [X] #427 something"
want_done steps-epic-upper "OK issue: #427 CLOSED" "OK epic: #400 [x] #427" "OK flaky: 0"
steps_std -e 400
assert_case steps-epic-upper 0 steps-epic-upper

# Epic line: no line names #427 as a whole number (#4270, #42 and #1427 do not), so the epic line fails. The steps
# are already done, so the branch and worktree are gone and the run exits 1.
new_case steps-epic-missing
write_epic 400 "- [ ] #4270 other" "- [x] #42 more" "- [ ] #1427 extra"
want_done steps-epic-missing "OK issue: #427 CLOSED" "FAIL epic: #400 has no line naming #427" "OK flaky: 0"
steps_std -e 400
assert_case steps-epic-missing 1 steps-epic-missing
assert_refs steps-epic-missing 0 0 "$FX_S" 0

# Epic line: a line naming #427 without a checkbox is ignored, and the later unchecked line matches.
new_case steps-epic-no-box
write_epic 400 "Discussed #427 in the notes" "- [ ] #427 the story"
want_done steps-epic-no-box "OK issue: #427 CLOSED" "OK epic: #400 [ ] #427" "OK flaky: 0"
steps_std -e 400
assert_case steps-epic-no-box 0 steps-epic-no-box

# Epic line: a checkbox-less line naming #427 takes no default box, so the later checked line prints [x].
new_case steps-epic-no-box-checked
write_epic 400 "Discussed #427 in the notes" "- [x] #427 the story"
want_done steps-epic-no-box-checked "OK issue: #427 CLOSED" "OK epic: #400 [x] #427" "OK flaky: 0"
steps_std -e 400
assert_case steps-epic-no-box-checked 0 steps-epic-no-box-checked

# Epic line: when the only line naming #427 has no checkbox, no line matches and the epic line fails (exit 1).
new_case steps-epic-only-no-box
write_epic 400 "Discussed #427 in the notes"
want_done steps-epic-only-no-box "OK issue: #427 CLOSED" "FAIL epic: #400 has no line naming #427" "OK flaky: 0"
steps_std -e 400
assert_case steps-epic-only-no-box 1 steps-epic-only-no-box
assert_refs steps-epic-only-no-box 0 0 "$FX_S" 0

# Epic line: the first matching line wins, so the checked line above the unchecked one prints [x].
new_case steps-epic-first
write_epic 400 "- [x] #427 first" "- [ ] #427 second"
want_done steps-epic-first "OK issue: #427 CLOSED" "OK epic: #400 [x] #427" "OK flaky: 0"
steps_std -e 400
assert_case steps-epic-first 0 steps-epic-first

# Flaky count: distinct head SHAs with both a failure and a success run. Zero, one and two shas, and the runs of
# one sha counted once.
steps_flaky_case steps-flaky-success-only '[{"headSha":"a","conclusion":"success"},{"headSha":"b","conclusion":"success"}]' 0
steps_flaky_case steps-flaky-failure-only '[{"headSha":"a","conclusion":"failure"},{"headSha":"b","conclusion":"failure"}]' 0
steps_flaky_case steps-flaky-one '[{"headSha":"a","conclusion":"failure"},{"headSha":"a","conclusion":"success"}]' 1
steps_flaky_case steps-flaky-two '[{"headSha":"a","conclusion":"failure"},{"headSha":"a","conclusion":"success"},{"headSha":"b","conclusion":"success"},{"headSha":"b","conclusion":"failure"},{"headSha":"c","conclusion":"failure"}]' 2
steps_flaky_case steps-flaky-repeat '[{"headSha":"a","conclusion":"failure"},{"headSha":"a","conclusion":"failure"},{"headSha":"a","conclusion":"success"}]' 1
steps_flaky_case steps-flaky-cancelled '[{"headSha":"a","conclusion":"cancelled"},{"headSha":"a","conclusion":"success"}]' 0
steps_flaky_case steps-flaky-cancelled-failure '[{"headSha":"a","conclusion":"cancelled"},{"headSha":"a","conclusion":"failure"}]' 0
steps_flaky_case steps-flaky-skipped '[{"headSha":"a","conclusion":"skipped"},{"headSha":"a","conclusion":"failure"}]' 0
steps_flaky_case steps-flaky-empty '[]' 0

# gh failures: each read fails on its own (exit 1) while the other two read fine. The steps are done; exit 1.
new_case steps-issue-gh-fails
write_epic 400 "- [ ] #427 the story"
touch "$TEST_TMP/fail-issue" || exit 2
want_done steps-issue-gh-fails "FAIL issue: gh failed" "OK epic: #400 [ ] #427" "OK flaky: 0"
steps_std -e 400
assert_case steps-issue-gh-fails 1 steps-issue-gh-fails
assert_refs steps-issue-gh-fails 0 0 "$FX_S" 0

new_case steps-epic-gh-fails
write_epic 400 "- [ ] #427 the story"
touch "$TEST_TMP/fail-epic" || exit 2
want_done steps-epic-gh-fails "OK issue: #427 CLOSED" "FAIL epic: gh failed" "OK flaky: 0"
steps_std -e 400
assert_case steps-epic-gh-fails 1 steps-epic-gh-fails
assert_refs steps-epic-gh-fails 0 0 "$FX_S" 0

new_case steps-flaky-gh-fails
write_epic 400 "- [ ] #427 the story"
touch "$TEST_TMP/fail-flaky" || exit 2
want_done steps-flaky-gh-fails "OK issue: #427 CLOSED" "OK epic: #400 [ ] #427" "FAIL flaky: gh failed"
steps_std -e 400
assert_case steps-flaky-gh-fails 1 steps-flaky-gh-fails
assert_refs steps-flaky-gh-fails 0 0 "$FX_S" 0

# Invalid JSON from one read counts as a gh failure for that read only.
new_case steps-issue-bad-json
write_epic 400 "- [ ] #427 the story"
touch "$TEST_TMP/bad-issue" || exit 2
want_done steps-issue-bad-json "FAIL issue: gh failed" "OK epic: #400 [ ] #427" "OK flaky: 0"
steps_std -e 400
assert_case steps-issue-bad-json 1 steps-issue-bad-json

new_case steps-epic-bad-json
write_epic 400 "- [ ] #427 the story"
touch "$TEST_TMP/bad-epic" || exit 2
want_done steps-epic-bad-json "OK issue: #427 CLOSED" "FAIL epic: gh failed" "OK flaky: 0"
steps_std -e 400
assert_case steps-epic-bad-json 1 steps-epic-bad-json

new_case steps-flaky-bad-json
write_epic 400 "- [ ] #427 the story"
touch "$TEST_TMP/bad-flaky" || exit 2
want_done steps-flaky-bad-json "OK issue: #427 CLOSED" "OK epic: #400 [ ] #427" "FAIL flaky: gh failed"
steps_std -e 400
assert_case steps-flaky-bad-json 1 steps-flaky-bad-json

# Refused run with -e and a flaky run list: the check fails (the PR is OPEN), so none of the issue, epic or flaky lines
# print.
new_case steps-refused-new-lines
write_epic 400 "- [ ] #427 the story"
write_runs '[{"headSha":"a","conclusion":"failure"},{"headSha":"a","conclusion":"success"}]'
write_merge OPEN null
steps_prefetch
check_alone steps-refused-new-lines
want steps-refused-new-lines "FAIL merged: state is OPEN" "$NOTE_FETCH" "FAIL ancestry: no merge commit" \
  "FAIL patch: no merge commit" "OK worktree: $FX_WT clean" "FAIL steps: refused, close-out check failed"
steps_snapshot "$TEST_TMP/before-steps-refused-new-lines" || exit 2
steps_std -e 400
assert_case steps-refused-new-lines 1 steps-refused-new-lines
check_prefix_eq steps-refused-new-lines
steps_compare steps-refused-new-lines "$TEST_TMP/before-steps-refused-new-lines"

# Steps usage errors (exit 2): each missing required option, an unknown option, and each option with no value.
new_case steps-usage
steps_usage_case missing-i -r "$FX_ROOT" -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX"
steps_usage_case missing-r -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX" -i 427
steps_usage_case missing-n -r "$FX_ROOT" -b "$FX_BRANCH" -p "$FX_PREFIX" -i 427
steps_usage_case missing-b -r "$FX_ROOT" -n 431 -p "$FX_PREFIX" -i 427
steps_usage_case missing-p -r "$FX_ROOT" -n 431 -b "$FX_BRANCH" -i 427
steps_usage_case unknown-option -r "$FX_ROOT" -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX" -i 427 -z
steps_usage_case value-r -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX" -i 427 -r
steps_usage_case value-i -r "$FX_ROOT" -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX" -i
steps_usage_case value-e -r "$FX_ROOT" -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX" -i 427 -e
steps_usage_case value-x -r "$FX_ROOT" -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX" -i 427 -x
steps_usage_case value-P -r "$FX_ROOT" -n 431 -b "$FX_BRANCH" -p "$FX_PREFIX" -i 427 -P

test_summary
