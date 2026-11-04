#!/bin/sh
# handback-check.sh -n <PR> -w <runner worktree> -s <story> [-b <base ref>] [-P <plan file>]
#                   [-m <old file> <new file> <text>]...
# Prints one line per check: "OK <name>: <value>" or "FAIL <name>: <value>".
# Exit 0 when every check is OK, 1 when any check fails or GitHub cannot be read, 2 on a usage error.
# GitHub is read by one function that runs "${HANDBACK_GH:-gh}" pr view; no other network use.
# -b is the base ref for the branch check (remote and branch split at the first slash); -P and -m are
# parsed and stored here; the checks that use them come in later todos.
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
      case "$2" in
        */*) BASE=$2 ;;
        *) usage ;;
      esac
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

# check_field <name> <field> <expected>: the PR field equals the expected value.
check_field() {
  _v=$(pr_field "$2")
  if [ "$_v" = "$3" ]; then
    emit ok "$1" "$_v"
  else
    emit fail "$1" "$_v"
  fi
}

# check_state: the PR is OPEN.
check_state() {
  check_field state state OPEN
}

# check_draft: the PR is not a draft.
check_draft() {
  check_field draft isDraft false
}

# check_mergeable: GitHub reports the PR as MERGEABLE (UNKNOWN and CONFLICTING fail).
check_mergeable() {
  check_field mergeable mergeable MERGEABLE
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

# check_ci: every statusCheckRollup entry is SUCCESS. A CheckRun uses its conclusion when non-empty,
# else its status; a StatusContext uses its state. Entries are named by name (CheckRun) or context.
check_ci() {
  # _eff: jq definition of the effective state of one rollup entry (the conclusion, else the status).
  _eff='def eff: if .__typename == "StatusContext" then .state elif ((.conclusion // "") != "") then .conclusion else (.status // "") end;'
  _total=$(printf '%s\n' "$PR_JSON" | jq -r '(.statusCheckRollup // []) | length') || {
    emit fail ci "rollup unreadable"
    return
  }
  if [ "$_total" -eq 0 ]; then
    emit fail ci "no checks"
    return
  fi
  _nbad=$(printf '%s\n' "$PR_JSON" | jq -r "$_eff"'[(.statusCheckRollup // [])[] | eff | select(. != "SUCCESS")] | length') || {
    emit fail ci "rollup unreadable"
    return
  }
  if [ "$_nbad" -eq 0 ]; then
    emit ok ci "$_total checks successful"
    return
  fi
  _bad=$(printf '%s\n' "$PR_JSON" | jq -r "$_eff"'[(.statusCheckRollup // [])[] | {n: (if .__typename == "StatusContext" then .context else .name end), s: eff} | select(.s != "SUCCESS") | "\(.n)=\(.s)"] | join(",")') || {
    emit fail ci "rollup unreadable"
    return
  }
  emit fail ci "$_nbad of $_total not successful: $_bad"
}

# check_branch: the runner branch is not behind its base ref after a fetch of the base branch. The
# base ref is split at its first slash into the remote and the branch. A NOTE line says what ran.
# Ahead is reported in the value; only behind fails.
check_branch() {
  _remote=${BASE%%/*}
  _branch=${BASE#*/}
  _fetch_ok=1
  GIT_TERMINAL_PROMPT=0 git -C "$WT" fetch "$_remote" "$_branch" >/dev/null 2>&1 || _fetch_ok=0
  printf 'NOTE fetch: ran git fetch %s %s\n' "$_remote" "$_branch"
  if [ "$_fetch_ok" -eq 0 ]; then
    emit fail branch "fetch failed"
    return
  fi
  if ! _counts=$(git -C "$WT" rev-list --left-right --count "$BASE...HEAD" 2>/dev/null); then
    emit fail branch "position unreadable"
    return
  fi
  _behind=$(printf '%s\n' "$_counts" | awk '{print $1}')
  _ahead=$(printf '%s\n' "$_counts" | awk '{print $2}')
  if [ "$_behind" -eq 0 ]; then
    emit ok branch "behind $_behind, ahead $_ahead"
  else
    emit fail branch "behind $_behind, ahead $_ahead"
  fi
}

if ! fetch_pr; then
  for _name in state draft mergeable head ci branch; do
    emit fail "$_name" "gh failed"
  done
  exit 1
fi

check_state
check_draft
check_mergeable
check_head
check_ci
check_branch

if [ "$FAILS" -eq 0 ]; then
  exit 0
fi
exit 1
