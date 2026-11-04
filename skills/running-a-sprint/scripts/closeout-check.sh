#!/bin/sh
# closeout-check.sh -r <repo root> -n <PR> -b <branch> -p <prefix> [-x <reconcile prefix>] [-P <plan file>]
# Prints one line per check: "OK <name>: <value>" or "FAIL <name>: <value>", in this order: merged, a NOTE
# line for the fetch, ancestry, patch, then the worktree lines. Exit 0 when every line is OK, 1 when any line
# fails, 2 on a usage error (usage on stderr, nothing on stdout).
# -r must be an absolute path to the repository root. -p is the runner worktree prefix: the runner worktree is
# <root>/.worktrees/<prefix> and the child worktrees are the registered <root>/.worktrees/<prefix>-*. With -x the
# same is done for <root>/.worktrees/<x> and its children, the patch check then uses origin/<branch> as the
# branch tip, and without -x it uses the local branch <branch>. -P is the plan file name a clean worktree may
# hold untracked at its top (default plan.md).
# GitHub is read by one function that runs "${CLOSEOUT_GH:-gh}" pr view; git runs a fetch of origin main and
# <branch> (remote refs only); nothing else changes in the repositories.
ROOT=""
PR=""
BRANCH=""
PREFIX=""
RECON=""
PLAN="plan.md"
FAILS=0
GH_OK=0
FETCH_OK=0
MERGE_STATE=""
MERGE_SHA=""
TMP=""

# usage: print the usage line to stderr and exit 2.
usage() {
  printf 'usage: closeout-check.sh -r <repo root> -n <PR> -b <branch> -p <prefix> [-x <reconcile prefix>] [-P <plan file>]\n' >&2
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
    *)
      usage
      ;;
  esac
done

if [ -z "$ROOT" ] || [ -z "$PR" ] || [ -z "$BRANCH" ] || [ -z "$PREFIX" ]; then
  usage
fi

TMP=$(mktemp -d) || exit 2
trap 'rm -rf "$TMP"' EXIT

# emit <line>: print one result line and count a failure when it starts with FAIL.
emit() {
  case "$1" in
    FAIL*) FAILS=$((FAILS + 1)) ;;
  esac
  printf '%s\n' "$1"
}

# read_merge: read the PR state and merge commit sha into MERGE_STATE and MERGE_SHA. Returns 1 when gh fails
# or the output is not JSON; both values are then empty.
read_merge() {
  MERGE_STATE=""
  MERGE_SHA=""
  "${CLOSEOUT_GH:-gh}" pr view "$PR" --json state,mergeCommit > "$TMP/pr.json" || return 1
  MERGE_STATE=$(jq -r '.state' "$TMP/pr.json") || {
    MERGE_STATE=""
    return 1
  }
  MERGE_SHA=$(jq -r '.mergeCommit.oid // ""' "$TMP/pr.json") || {
    MERGE_STATE=""
    MERGE_SHA=""
    return 1
  }
  return 0
}

# check_merged: the PR state is MERGED and it has a merge commit, which the line prints.
check_merged() {
  if [ "$GH_OK" -ne 1 ]; then
    emit "FAIL merged: gh failed"
  elif [ "$MERGE_STATE" != MERGED ]; then
    emit "FAIL merged: state is $MERGE_STATE"
  elif [ -z "$MERGE_SHA" ]; then
    emit "FAIL merged: no merge commit"
  else
    emit "OK merged: $MERGE_SHA"
  fi
}

# run_fetch: fetch origin main and the branch as remote refs only. Always prints the NOTE line; FETCH_OK is 1
# when the fetch succeeded.
run_fetch() {
  FETCH_OK=0
  if GIT_TERMINAL_PROMPT=0 git -C "$ROOT" fetch -q origin main "$BRANCH" >/dev/null 2>&1; then
    FETCH_OK=1
  fi
  printf 'NOTE fetch: ran git fetch origin main %s\n' "$BRANCH"
}

# check_ancestry: the merge commit is reachable from origin/main after the fetch.
check_ancestry() {
  if [ -z "$MERGE_SHA" ]; then
    emit "FAIL ancestry: no merge commit"
    return
  fi
  if [ "$FETCH_OK" -ne 1 ]; then
    emit "FAIL ancestry: fetch failed"
    return
  fi
  _s7=$(printf '%.7s' "$MERGE_SHA")
  if git -C "$ROOT" merge-base --is-ancestor "$MERGE_SHA" origin/main >/dev/null 2>&1; then
    emit "OK ancestry: $_s7 is in origin/main"
  else
    emit "FAIL ancestry: $_s7 is not in origin/main"
  fi
}

# check_patch: the squash commit's diff equals the branch diff from the merge base. The squash diff is S^ to S;
# the branch diff is B to H, with B the merge base of S^ and H, and H the local branch (origin/<branch> with -x).
# Lines starting with "index " are removed from both diffs before the byte comparison.
check_patch() {
  if [ -z "$MERGE_SHA" ]; then
    emit "FAIL patch: no merge commit"
    return
  fi
  if [ "$FETCH_OK" -ne 1 ]; then
    emit "FAIL patch: fetch failed"
    return
  fi
  if [ -n "$RECON" ]; then
    _tip="refs/remotes/origin/$BRANCH"
  else
    _tip="refs/heads/$BRANCH"
  fi
  if ! _h=$(git -C "$ROOT" rev-parse -q --verify "$_tip^{commit}" 2>/dev/null) || [ -z "$_h" ]; then
    emit "FAIL patch: branch tip not found"
    return
  fi
  if ! _b=$(git -C "$ROOT" merge-base "$MERGE_SHA^" "$_h" 2>/dev/null) || [ -z "$_b" ]; then
    emit "FAIL patch: squash differs from branch diff"
    return
  fi
  if git -C "$ROOT" diff --no-color --no-ext-diff "$_b" "$_h" > "$TMP/branch.raw" 2>/dev/null &&
    git -C "$ROOT" diff --no-color --no-ext-diff "$MERGE_SHA^" "$MERGE_SHA" > "$TMP/squash.raw" 2>/dev/null &&
    sed '/^index /d' "$TMP/branch.raw" > "$TMP/branch.diff" &&
    sed '/^index /d' "$TMP/squash.raw" > "$TMP/squash.diff" &&
    cmp -s "$TMP/branch.diff" "$TMP/squash.diff"; then
    emit "OK patch: squash equals branch diff"
  else
    emit "FAIL patch: squash differs from branch diff"
  fi
}

# check_worktree <path>: the path is absent (OK absent), or its status shows nothing but the plan file as an
# untracked line (OK clean), or it names every status line verbatim, joined with ", " (FAIL has).
check_worktree() {
  if [ ! -d "$1" ]; then
    emit "OK worktree: $1 absent"
    return
  fi
  if ! git -C "$1" status --short --ignored > "$TMP/status" 2>/dev/null; then
    emit "FAIL worktree: $1 status failed"
    return
  fi
  if awk -v plan="?? $PLAN" '$0 != plan { bad = 1 } END { exit bad }' "$TMP/status"; then
    emit "OK worktree: $1 clean"
  else
    emit "FAIL worktree: $1 has $(awk 'NR > 1 { printf ", " } { printf "%s", $0 }' "$TMP/status")"
  fi
}

# list_registered <prefix path>: print the registered worktree paths that begin with the prefix, sorted by path.
list_registered() {
  git -C "$ROOT" worktree list --porcelain | awk -v pre="$1" '
    index($0, "worktree ") == 1 && index(substr($0, 10), pre) == 1 { print substr($0, 10) }' | LC_ALL=C sort
}

# check_children <prefix path>: one worktree check per registered child, in path order.
check_children() {
  list_registered "$1" > "$TMP/children"
  while IFS= read -r _c; do
    [ -n "$_c" ] || continue
    check_worktree "$_c"
  done < "$TMP/children"
}

# check_worktrees: the runner worktree, its children, then with -x the reconcile worktree and its children.
check_worktrees() {
  check_worktree "$ROOT/.worktrees/$PREFIX"
  check_children "$ROOT/.worktrees/$PREFIX-"
  if [ -n "$RECON" ]; then
    check_worktree "$ROOT/.worktrees/$RECON"
    check_children "$ROOT/.worktrees/$RECON-"
  fi
}

if read_merge; then
  GH_OK=1
fi
check_merged
run_fetch
check_ancestry
check_patch
check_worktrees

if [ "$FAILS" -eq 0 ]; then
  exit 0
fi
exit 1
