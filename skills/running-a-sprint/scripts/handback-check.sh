#!/bin/sh
# handback-check.sh -n <PR> -w <runner worktree> -s <story> [-b <base ref>] [-P <plan file>]
#                   [-m <old file> <new file> <text>]...
# Prints one line per check: "OK <name>: <value>" or "FAIL <name>: <value>".
# Exit 0 when every check is OK, 1 when any check fails or GitHub cannot be read, 2 on a usage error.
# GitHub is read by one function that runs "${HANDBACK_GH:-gh}" pr view; no other network use.
# -b, -P and -m are parsed and stored here; the checks that use them come in later todos.
# shellcheck disable=SC2034
PR=""
WT=""
STORY=""
BASE="origin/main"
PLAN="plan.md"
MAP_COUNT=0
MAP_OLD=""
MAP_NEW=""
MAP_TEXT=""
FAILS=0
PR_JSON=""

# usage: print the usage line to stderr and exit 2.
usage() {
  printf 'usage: handback-check.sh -n <PR> -w <runner worktree> -s <story> [-b <base ref>] [-P <plan file>] [-m <old> <new> <text>]...\n' >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -n)
      [ "$#" -ge 2 ] || usage
      PR=$2
      shift 2
      ;;
    -w)
      [ "$#" -ge 2 ] || usage
      WT=$2
      shift 2
      ;;
    -s)
      [ "$#" -ge 2 ] || usage
      STORY=$2
      shift 2
      ;;
    -b)
      [ "$#" -ge 2 ] || usage
      BASE=$2
      shift 2
      ;;
    -P)
      [ "$#" -ge 2 ] || usage
      PLAN=$2
      shift 2
      ;;
    -m)
      [ "$#" -ge 4 ] || usage
      MAP_OLD=$2
      MAP_NEW=$3
      MAP_TEXT=$4
      MAP_COUNT=$((MAP_COUNT + 1))
      shift 4
      ;;
    *)
      usage
      ;;
  esac
done

if [ -z "$PR" ] || [ -z "$WT" ] || [ -z "$STORY" ]; then
  usage
fi

# emit <ok|fail> <name> <value>: print one result line and count a failure.
emit() {
  if [ "$1" = ok ]; then
    printf 'OK %s: %s\n' "$2" "$3"
  else
    printf 'FAIL %s: %s\n' "$2" "$3"
    FAILS=$((FAILS + 1))
  fi
}

# fetch_pr: read the PR document into PR_JSON. Returns 1 when gh fails or the output is not JSON.
fetch_pr() {
  PR_JSON=$("${HANDBACK_GH:-gh}" pr view "$PR" --json number,state,isDraft,mergeable,headRefOid,statusCheckRollup,body) || return 1
  printf '%s\n' "$PR_JSON" | jq -e . >/dev/null 2>&1 || return 1
  return 0
}

# pr_field <name>: one top-level field of PR_JSON as raw text.
pr_field() {
  printf '%s\n' "$PR_JSON" | jq -r ".$1"
}

# check_state: the PR is OPEN.
check_state() {
  _v=$(pr_field state)
  if [ "$_v" = OPEN ]; then
    emit ok state "$_v"
  else
    emit fail state "$_v"
  fi
}

# check_draft: the PR is not a draft.
check_draft() {
  _v=$(pr_field isDraft)
  if [ "$_v" = false ]; then
    emit ok draft "$_v"
  else
    emit fail draft "$_v"
  fi
}

# check_mergeable: GitHub reports the PR as MERGEABLE (UNKNOWN and CONFLICTING fail).
check_mergeable() {
  _v=$(pr_field mergeable)
  if [ "$_v" = MERGEABLE ]; then
    emit ok mergeable "$_v"
  else
    emit fail mergeable "$_v"
  fi
}

# check_head: the PR head is the commit checked out in the runner worktree.
check_head() {
  _pr=$(pr_field headRefOid)
  if ! _wt=$(git -C "$WT" rev-parse HEAD 2>/dev/null) || [ -z "$_wt" ]; then
    emit fail head "worktree HEAD unreadable"
    return
  fi
  if [ "$_pr" = "$_wt" ]; then
    emit ok head "$_pr"
  else
    emit fail head "pr $_pr worktree $_wt"
  fi
}

if ! fetch_pr; then
  for _name in state draft mergeable head; do
    emit fail "$_name" "gh failed"
  done
  exit 1
fi

check_state
check_draft
check_mergeable
check_head

if [ "$FAILS" -eq 0 ]; then
  exit 0
fi
exit 1
