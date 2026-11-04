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

# ci_query <filter>: run a jq filter over PR_JSON with the effective-state definition in front. The
# effective state of a rollup entry is its conclusion when non-empty, else its status; a StatusContext
# uses its state.
ci_query() {
  printf '%s\n' "$PR_JSON" | jq -r 'def eff: if .__typename == "StatusContext" then .state elif ((.conclusion // "") != "") then .conclusion else (.status // "") end;'"$1"
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
  _total=$(ci_query '(.statusCheckRollup // []) | length') || {
    emit fail ci "rollup unreadable"
    return
  }
  if [ "$_total" -eq 0 ]; then
    emit fail ci "no checks"
    return
  fi
  _nbad=$(ci_query '[(.statusCheckRollup // [])[] | eff | select(. != "SUCCESS")] | length') || {
    emit fail ci "rollup unreadable"
    return
  }
  if [ "$_nbad" -eq 0 ]; then
    emit ok ci "$_total checks successful"
    return
  fi
  _bad=$(ci_query '[(.statusCheckRollup // [])[] | {n: (if .__typename == "StatusContext" then .context else .name end), s: eff} | select(.s != "SUCCESS") | "\(.n)=\(.s)"] | join(",")') || {
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

# closing_refs: read a PR body on stdin and print each issue reference that follows a closing keyword,
# in body order. A reference is #N or owner/repo#N; a chain joined by commas, "and" or "&" is read in
# full. Keywords are whole words in any case, with an optional colon. CR bytes are stripped first.
closing_refs() {
  tr -d '\r' | LC_ALL=C grep -oiE '(^|[^[:alnum:]_])(close|closes|closed|fix|fixes|fixed|resolve|resolves|resolved)(:[[:space:]]*|[[:space:]]+)([[:alnum:]_.-]+/[[:alnum:]_.-]+)?#[0-9]+([[:space:]]*(,|&|and)[[:space:]]*([[:alnum:]_.-]+/[[:alnum:]_.-]+)?#[0-9]+)*' | LC_ALL=C grep -oE '([[:alnum:]_.-]+/[[:alnum:]_.-]+)?#[0-9]+'
}

# closing_others: read references on stdin and print those that do not name the story -s (a numeric
# compare), each once, comma-joined in input order. Prints an empty line when there are none.
closing_others() {
  awk -v story="$STORY" '
    $0 == "" { next }
    /^#[0-9]+$/ && substr($0, 2) + 0 == story + 0 { next }
    !($0 in seen) { seen[$0] = 1; list = list (list == "" ? "" : ",") $0 }
    END { print list }'
}

# check_closing: a closing keyword names the story and no other issue. Any other reference fails, even
# when the story is not named; a body with no reference at all fails with no keyword.
check_closing() {
  _refs=$(pr_field 'body // ""' | closing_refs)
  _others=$(printf '%s\n' "$_refs" | closing_others)
  if [ -n "$_others" ]; then
    emit fail closing "also names $_others"
  elif [ -n "$_refs" ]; then
    emit ok closing "names #$STORY"
  else
    emit fail closing "no closing keyword for #$STORY"
  fi
}

# check_footer: the last non-empty body line, CR and trailing blanks stripped, is one of the two footer
# lines exactly.
check_footer() {
  _last=$(pr_field 'body // ""' | tr -d '\r' | sed -e 's/[[:blank:]]*$//' -e '/^$/d' | tail -n 1)
  case "$_last" in
    '')
      emit fail footer "empty body"
      ;;
    'Generated with Claude Code' | 'Generated with [Claude Code](https://claude.com/claude-code)')
      emit ok footer "$_last"
      ;;
    *)
      emit fail footer "last line is \"$_last\""
      ;;
  esac
}

# check_coauthor: no Co-Authored-By line (any case, optional leading spaces) in the body or in a commit
# message of base..HEAD. A body hit names "body"; a commit hit names "commit <sha>", newest first.
check_coauthor() {
  _bhit=$(pr_field 'body // ""' | tr -d '\r' | grep -ciE '^ *co-authored-by:')
  if ! _log=$(git -C "$WT" log --abbrev=7 --format='%x01%h%n%B' "$BASE..HEAD") ||
    ! _n=$(git -C "$WT" rev-list --count "$BASE..HEAD"); then
    emit fail coauthor "commits unreadable"
    return
  fi
  _all=$(printf '%s\n' "$_log" | awk '
    /^\001/ { sha = substr($0, 2); next }
    tolower($0) ~ /^ *co-authored-by:/ && !(sha in seen) { seen[sha] = 1; list = list (list == "" ? "" : "; ") "commit " sha }
    END { print list }')
  if [ "$_bhit" -gt 0 ]; then
    if [ -n "$_all" ]; then
      _all="body; $_all"
    else
      _all=body
    fi
  fi
  if [ -n "$_all" ]; then
    emit fail coauthor "$_all"
  else
    emit ok coauthor "none in body or $_n commits"
  fi
}

# check_ascii: the body as GitHub returns it (CR kept) holds only printable ASCII, tab, CR and newline.
# LC_ALL=C is set for the scan so that every non-ASCII byte counts.
check_ascii() {
  _bad=$(pr_field 'body // ""' | LC_ALL=C awk '/[^\t\r -~]/ { print NR; exit }')
  if [ -z "$_bad" ]; then
    emit ok ascii "body is ASCII"
  else
    emit fail ascii "non-ASCII byte on line $_bad"
  fi
}

if ! fetch_pr; then
  for _name in state draft mergeable head ci branch closing footer coauthor ascii; do
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
check_closing
check_footer
check_coauthor
check_ascii

if [ "$FAILS" -eq 0 ]; then
  exit 0
fi
exit 1
