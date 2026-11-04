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
# A failing step prints FAIL <step>: <first line of the git error output>, then the line
# FAIL steps: stopped, later steps not run; nothing after it runs. Exit codes: 0 every step OK, 1 a refusal or a
# failed step, 2 a usage error (usage on stderr, nothing on stdout). -i is required, and no step uses its value.
# -e is accepted and ignored.
# Removal uses git worktree remove --force: the check has already allowed only the plan file to be untracked, and
# a locked worktree still fails. Branches are deleted with branch -D because a squash merge leaves the branch
# unmerged in git's view; the check has already compared the patches. Nothing is pushed with --force, and nothing
# outside these steps is changed. A detached root HEAD is named "detached HEAD" in the refusal line.
ROOT=""
PR=""
BRANCH=""
PREFIX=""
RECON=""
PLAN=""
ISSUE=""
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
  GIT_TERMINAL_PROMPT=0 git -C "$ROOT" ls-remote --exit-code --heads origin "$1" >/dev/null 2>"$TMP/err" || _ls=$?
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
exit 0
