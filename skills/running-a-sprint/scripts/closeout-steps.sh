#!/bin/sh
# closeout-steps.sh -r <repo root> -n <PR> -b <branch> -p <prefix> [-x <reconcile prefix>] [-P <plan file name>] -i <issue number> [-e <epic issue number>]
# First runs closeout-check.sh with the same options (or the script named by CLOSEOUT_CHECK) and prints its output
# unchanged. A non-zero check, or a repo root not on main, refuses the run before any change. Then the steps, one
# line each, in order:
#   1. remove-worktree: the runner worktree <root>/.worktrees/<prefix>, then its registered children
#      <prefix>-* in path order; with -x the same for <root>/.worktrees/<x> and its children.
#   2. delete-branch-local: <branch>, then with -x reconcile-<x>; a branch that does not exist is already gone.
#   3. delete-branch-origin: <branch> on origin, checked with git ls-remote; already gone when absent.
#   4. fast-forward: root main to origin/main with --ff-only.
# After the steps, three reads print one line each, in this order:
#   issue: OK issue: #<issue> <state>, the state from gh issue view.
#   epic: only with -e. The first line of the epic body whose checkbox (- [x], - [X] or - [ ]) starts the line
#     after optional spaces or tabs, and whose first #<number> after the box is #<issue> as a whole number, prints
#     OK epic: #<epic> [x] #<issue> or [ ]; no such line prints FAIL epic: #<epic> has no line naming #<issue>.
#   flaky: OK flaky: <count>, the distinct head SHAs of <branch> that have both a run with conclusion failure
#     and a run with conclusion success in gh run list (other conclusions, such as startup_failure, do not count).
# A read whose gh call exits non-zero or prints invalid JSON prints FAIL <read>: gh failed, and the other reads
# still run. The GitHub reads run "${CLOSEOUT_GH:-gh}"; no read changes anything. Any FAIL read makes the exit 1.
# A failing step prints FAIL <step>: <first line of the git error output>, then the line
# FAIL steps: stopped, later steps not run; nothing after it runs. Exit codes: 0 every step and read OK, 1 a refusal,
# a failed step or a failed read, 2 a usage error (usage on stderr, nothing on stdout). -i is required; -e is
# optional and names the epic issue.
# Removal uses git worktree remove --force: the check has already allowed only the plan file to be untracked, and
# a locked worktree still fails. Branches are deleted with branch -D because a squash merge leaves the branch
# unmerged in git's view; the check has already compared the patches. Nothing is pushed with --force, and nothing
# outside these steps is changed. A detached root HEAD is named "detached HEAD" in the refusal line. A trailing
# slash on -r is stripped; a relative -r is a usage error (exit 2) before anything runs.
ROOT=""
PR=""
BRANCH=""
PREFIX=""
RECON=""
PLAN=""
ISSUE=""
EPIC=""
TMP=""

# usage: print the usage line to stderr and exit 2.
usage() {
  printf 'usage: closeout-steps.sh -r <repo root> -n <PR> -b <branch> -p <prefix> [-x <reconcile prefix>] [-P <plan file name>] -i <issue number> [-e <epic issue number>]\n' >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -r)
      [ "$#" -ge 2 ] || usage
      ROOT=$2
      shift 2
      ;;
    -n)
      [ "$#" -ge 2 ] || usage
      PR=$2
      shift 2
      ;;
    -b)
      [ "$#" -ge 2 ] || usage
      BRANCH=$2
      shift 2
      ;;
    -p)
      [ "$#" -ge 2 ] || usage
      PREFIX=$2
      shift 2
      ;;
    -x)
      [ "$#" -ge 2 ] || usage
      RECON=$2
      shift 2
      ;;
    -P)
      [ "$#" -ge 2 ] || usage
      PLAN=$2
      shift 2
      ;;
    -i)
      [ "$#" -ge 2 ] || usage
      ISSUE=$2
      shift 2
      ;;
    -e)
      [ "$#" -ge 2 ] || usage
      EPIC=$2
      shift 2
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z "$ROOT" ] || [ -z "$PR" ] || [ -z "$BRANCH" ] || [ -z "$PREFIX" ] || [ -z "$ISSUE" ]; then
  usage
fi
case "$ROOT" in
  /*) ;;
  *) usage ;;
esac
while [ "$ROOT" != / ] && [ "${ROOT%/}" != "$ROOT" ]; do
  ROOT=${ROOT%/}
done

TMP=$(mktemp -d) || exit 2
trap 'rm -rf "$TMP"' EXIT
SELF_DIR=$(dirname "$0") || exit 2
CHECK=${CLOSEOUT_CHECK:-$SELF_DIR/closeout-check.sh}

# run_check: run the check with the run's options, print its output unchanged and return its exit status.
run_check() {
  set -- -r "$ROOT" -n "$PR" -b "$BRANCH" -p "$PREFIX"
  if [ -n "$RECON" ]; then
    set -- "$@" -x "$RECON"
  fi
  if [ -n "$PLAN" ]; then
    set -- "$@" -P "$PLAN"
  fi
  _rc=0
  "$CHECK" "$@" > "$TMP/check" || _rc=$?
  cat "$TMP/check"
  return "$_rc"
}

# check_root_branch: the repo root is on main, else refuse with the branch name and exit 1.
check_root_branch() {
  _cur=$(git -C "$ROOT" symbolic-ref --short HEAD 2>/dev/null) || _cur=""
  if [ "$_cur" != main ]; then
    printf 'FAIL steps: refused, repo root is on %s, not main\n' "${_cur:-detached HEAD}"
    exit 1
  fi
}

# stop_step <step name>: print the FAIL line with the first line of the git error output, then the stop line, and
# exit 1. The error output is read from TMP/err, which the failing command wrote.
stop_step() {
  _first=$(sed -n '1p' "$TMP/err")
  if [ -z "$_first" ]; then
    _first="git failed with no output"
  fi
  printf 'FAIL %s: %s\n' "$1" "$_first"
  printf 'FAIL steps: stopped, later steps not run\n'
  exit 1
}

# remove_worktree <path>: remove the registered worktree with git worktree remove --force, or print the absent line
# when the directory does not exist.
remove_worktree() {
  if [ ! -d "$1" ]; then
    printf 'OK remove-worktree: %s absent\n' "$1"
    return
  fi
  git -C "$ROOT" worktree remove --force "$1" >/dev/null 2>"$TMP/err" || stop_step remove-worktree
  printf 'OK remove-worktree: %s\n' "$1"
}

# list_children <prefix path>: print the registered worktree paths that begin with the prefix, sorted by path.
list_children() {
  git -C "$ROOT" worktree list --porcelain | awk -v pre="$1" '
    index($0, "worktree ") == 1 && index(substr($0, 10), pre) == 1 { print substr($0, 10) }' | LC_ALL=C sort
}

# remove_group <worktree path> <child prefix path>: remove the worktree, then its registered children in path order.
remove_group() {
  remove_worktree "$1"
  list_children "$2" > "$TMP/children"
  while IFS= read -r _c; do
    [ -n "$_c" ] || continue
    remove_worktree "$_c"
  done < "$TMP/children"
}

# delete_local <branch>: delete the local branch with branch -D when it exists, else print the already gone line.
delete_local() {
  if git -C "$ROOT" show-ref -q --verify "refs/heads/$1"; then
    git -C "$ROOT" branch -D "$1" >/dev/null 2>"$TMP/err" || stop_step delete-branch-local
    printf 'OK delete-branch-local: %s\n' "$1"
  else
    printf 'OK delete-branch-local: %s already gone\n' "$1"
  fi
}

# delete_origin <branch>: delete the branch on origin when ls-remote finds it. ls-remote exits 2 when the branch is
# absent (already gone); any other failure stops the run.
delete_origin() {
  _ls=0
  GIT_TERMINAL_PROMPT=0 git -C "$ROOT" ls-remote --exit-code origin "refs/heads/$1" >/dev/null 2>"$TMP/err" || _ls=$?
  case "$_ls" in
    0) ;;
    2)
      printf 'OK delete-branch-origin: %s already gone\n' "$1"
      return
      ;;
    *) stop_step delete-branch-origin ;;
  esac
  GIT_TERMINAL_PROMPT=0 git -C "$ROOT" push -q origin --delete "$1" >/dev/null 2>"$TMP/err" || stop_step delete-branch-origin
  printf 'OK delete-branch-origin: %s\n' "$1"
}

# fast_forward: move root main to origin/main with --ff-only and print the new main as its first 7 characters.
fast_forward() {
  git -C "$ROOT" merge -q --ff-only origin/main >/dev/null 2>"$TMP/err" || stop_step fast-forward
  _sha=$(git -C "$ROOT" rev-parse HEAD 2>"$TMP/err") || stop_step fast-forward
  printf 'OK fast-forward: main at %.7s\n' "$_sha"
}

# gh_read <file name> <gh arguments>: run the GitHub command named by CLOSEOUT_GH (default gh) with the arguments and
# write its output to TMP/<file name>. Returns the command's exit status; every GitHub read goes through here.
gh_read() {
  _gf=$1
  shift
  "${CLOSEOUT_GH:-gh}" "$@" > "$TMP/$_gf"
}

# gh_fail <label>: print the FAIL line of a read whose GitHub call failed or returned unusable output.
gh_fail() {
  printf 'FAIL %s: gh failed\n' "$1"
}

# read_issue: print the issue state line, or FAIL issue: gh failed when gh fails or the state is missing.
read_issue() {
  if ! gh_read issue.json issue view "$ISSUE" --json state; then
    gh_fail issue
    return 1
  fi
  _st=$(jq -r '.state // ""' "$TMP/issue.json") || _st=""
  if [ -z "$_st" ]; then
    gh_fail issue
    return 1
  fi
  printf 'OK issue: #%s %s\n' "$ISSUE" "$_st"
}

# epic_box: read the epic body on stdin and print the checkbox of the first line that starts with a checkbox
# (- [x], - [X] or - [ ], after optional leading spaces or tabs) whose first #<number> after the box is #<issue>.
# The number is compared as a whole digit run, so #4270 does not match 427. Prints nothing when no line does.
epic_box() {
  awk -v n="$ISSUE" '
{
  if (match($0, /^[ \t]*- \[[xX]\]/)) {
    b = "[x]"
  } else if (match($0, /^[ \t]*- \[ \]/)) {
    b = "[ ]"
  } else {
    next
  }
  rest = substr($0, RSTART + RLENGTH)
  if (match(rest, /#[0-9]+/) && substr(rest, RSTART + 1, RLENGTH - 1) == n) {
    print b
    exit
  }
}'
}

# read_epic: print the epic line for -e, or FAIL epic: gh failed, or FAIL epic: no line naming the issue.
read_epic() {
  if ! gh_read epic.json issue view "$EPIC" --json body; then
    gh_fail epic
    return 1
  fi
  if ! _body=$(jq -r '.body // ""' "$TMP/epic.json"); then
    gh_fail epic
    return 1
  fi
  _box=$(printf '%s\n' "$_body" | epic_box)
  if [ -z "$_box" ]; then
    printf 'FAIL epic: #%s has no line naming #%s\n' "$EPIC" "$ISSUE"
    return 1
  fi
  printf 'OK epic: #%s %s #%s\n' "$EPIC" "$_box" "$ISSUE"
}

# read_flaky: print the count of distinct head SHAs of the branch with both a failure and a success run (exact
# conclusion values, so startup_failure does not count as failure), or FAIL flaky: gh failed when gh fails or its
# output is not a run list.
read_flaky() {
  if ! gh_read runs.json run list --branch "$BRANCH" --json headSha,conclusion --limit 100; then
    gh_fail flaky
    return 1
  fi
  _n=$(jq -r 'if type == "array" then ([group_by(.headSha)[] | map(.conclusion) | select(any(.[]; . == "failure") and any(.[]; . == "success"))] | length) else error("not an array") end' "$TMP/runs.json") || _n=""
  if [ -z "$_n" ]; then
    gh_fail flaky
    return 1
  fi
  printf 'OK flaky: %s\n' "$_n"
}

run_check || {
  printf 'FAIL steps: refused, close-out check failed\n'
  exit 1
}
check_root_branch

remove_group "$ROOT/.worktrees/$PREFIX" "$ROOT/.worktrees/$PREFIX-"
if [ -n "$RECON" ]; then
  remove_group "$ROOT/.worktrees/$RECON" "$ROOT/.worktrees/$RECON-"
fi
delete_local "$BRANCH"
if [ -n "$RECON" ]; then
  delete_local "reconcile-$RECON"
fi
delete_origin "$BRANCH"
fast_forward

_rc=0
read_issue || _rc=1
if [ -n "$EPIC" ]; then
  read_epic || _rc=1
fi
read_flaky || _rc=1
exit "$_rc"
