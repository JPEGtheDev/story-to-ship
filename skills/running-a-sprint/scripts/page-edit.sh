#!/bin/sh
# page-edit.sh <op> <page file> <input file>
# Edits the owner question page (built from references/owner-questions-template.html) in place. Ops: add-card, hide,
# status, ready-add and ready-remove. The input file holds key=value lines, each split at its first "="; a key the op
# does not read is ignored.
#   add-card: before=<id> card=<html> [context=<html>]
#     card is one line of HTML holding exactly one id attribute, id="<id>", and the id is not empty. It is inserted
#     directly above the line that holds id="<before>", with that line's indent. context, when given, is one line of
#     HTML inserted directly above the line that holds id="c-<before>", with that line's indent. The card id must not
#     already be on the page. context holds exactly one id attribute, and that id must be c-<card id>: no id, an
#     empty id, two or more ids or any other id fails, and the page is not changed. The c-<card id> anchor must not
#     already be on the page.
#   hide: hide=<id> (repeatable)
#     The card block is the line that holds id="<id>" through the first later line equal to that line's indent plus
#     the closing tag of the element that line opens, or that line alone when it holds as many closing tags of that
#     element as opening tags of it. The context block is the same for id="c-<id>". Both blocks are removed. An id
#     given twice is removed once. When no line holds id="c-<id>", only the card block is removed and the output
#     carries "NOTE hide: <id> has no context section" after the OK line. Two or more lines holding id="c-<id>" fail.
#   status: status=<label> text=<text>
#     The line holding data-status="<label>" is one element: an opening tag, its text and its closing tag. The text
#     between the opening tag and the closing tag becomes "<label>: <text>" (the text is inserted as given). A label
#     may hold a space. Both keys are required; an empty value counts as missing.
#   ready-add: pr=<n> entry=<html>
#     pr is digits only: no pr key is "missing key pr", an empty or non-digit value is "must be a number". entry is one
#     line of HTML, the inside of the list item; required. The Ready to merge list is the first line after the line
#     holding id="ready" that opens a ul element (<ul followed by a space, a tab or >). The search stops at the first
#     later line that holds <section or <h2; with no list before that line the op fails "no list after anchor ready".
#     The line <li data-pr="<n>"> entry </li> goes directly below that list line, with that
#     line's indent plus two spaces, so the newest entry is first. A pr already on the page fails.
#   ready-remove: pr=<n>
#     The block of the line holding data-pr="<n>" is removed, found with the hide block rule (here the closing tag is
#     </li>, or the line alone when it also holds that closing tag). pr is checked as for ready-add.
# An anchor is attr="<value>" where the character before attr is the start of the line or any character other than a
# letter, digit, underscore or hyphen (so data-id="..." and href="#..." do not count, while class="a"id="x" does).
# The anchor ids (add-card, hide, ready-add) and the attributes data-status and data-pr (status, ready-add,
# ready-remove) must each occur exactly once, except that ready-add's data-pr must not occur at all and hide's
# c-<id> anchor may be absent (see hide).
# Output: on success one line per op: "OK add-card: <id> before <before>" (with " and context" when context was given),
# one "OK hide: <id>" line per distinct id, in the order first given (each followed by its NOTE line when its context
# section is absent), "OK status: <label>", "OK ready-add: <n>" or "OK ready-remove: <n>". On any failure exactly one
# line, "FAIL <op>: <reason>", on stdout, exit 1, and the page is not changed. A page or input that is not a readable
# regular file is a FAIL line too. Input bytes other than printable ASCII and tab fail the op; a carriage return
# fails with its own reason.
# Exit codes: 0 all OK, 1 a FAIL, 2 a usage error (usage on stderr, nothing on stdout).
# Everything is checked before anything is written. The result is built in a temp file made with mktemp in the page's
# directory, given the page's mode by cp -p, and moved over the page with mv only when every check passed; the temp
# file is removed on every exit that has not moved it.
# Tools: sh, awk, grep, mktemp, cp, mv and rm. No other command is used.
NL='
'
TAB=$(printf '\t')
CR=$(printf '\r')
export LC_ALL=C
OP=""
PAGE=""
IN=""
TMP=""
LINE=""
KEY=""
VAL=""
BEFORE=""
CARD=""
CONTEXT=""
CARD_IDS=0
NEW_ID=""
CTX_IDS=0
CTX_ID=""
HIDE_COUNT=0
SEEN="$NL"
RANGES=""
OUT=""
COUNT=0
FIRST=0
BLOCK_END=""
BEFORE_LINE=0
CTX_LINE=0
STATUS_LABEL=""
STATUS_TEXT=""
PR=""
PR_SEEN=0
ENTRY=""

# COUNT_FUNCS: awk functions shared by every anchor and attribute lookup. bound_ok: a match at column abs counts when
# the character before it is the start of the line or not a letter, digit, underscore or hyphen. count_in: counts the
# matches of a needle in one line. first_in: the column of the first matching needle in one line, or 0. id_in: the
# value of the first id="..." in one line that passes bound_ok (the text to the end of the line when the closing quote
# is missing), or "" when there is none.
COUNT_FUNCS='
function bound_ok(line, abs) {
  if (abs == 1) return 1
  return substr(line, abs - 1, 1) !~ /[A-Za-z0-9_-]/
}
function count_in(line, needle,   rest, offset, p, abs, n) {
  n = 0
  rest = line
  offset = 0
  while ((p = index(rest, needle)) > 0) {
    abs = offset + p
    if (bound_ok(line, abs)) n++
    rest = substr(line, abs + 1)
    offset = abs
  }
  return n
}
function first_in(line, needle,   rest, offset, p, abs) {
  rest = line
  offset = 0
  while ((p = index(rest, needle)) > 0) {
    abs = offset + p
    if (bound_ok(line, abs)) return abs
    rest = substr(line, abs + 1)
    offset = abs
  }
  return 0
}
function id_in(line,   rest, offset, p, abs, v, q) {
  rest = line
  offset = 0
  while ((p = index(rest, "id=\"")) > 0) {
    abs = offset + p
    if (bound_ok(line, abs)) {
      v = substr(line, abs + 4)
      q = index(v, "\"")
      if (q > 0) return substr(v, 1, q - 1)
      return v
    }
    rest = substr(line, abs + 1)
    offset = abs
  }
  return ""
}'

# INDENT_FUNC: the awk function indent_of, which returns the leading blanks of a line. Shared by every awk program
# that inserts or matches a block at a line's indent.
INDENT_FUNC='function indent_of(s) {
  sub(/[^[:blank:]].*$/, "", s)
  return s
}'

# usage: the usage line to stderr, exit 2.
usage() {
  printf 'usage: page-edit.sh <add-card|hide|status|ready-add|ready-remove> <page file> <input file>\n' >&2
  exit 2
}

# fail <reason>: one FAIL line on stdout for the op, then exit 1.
fail() {
  printf 'FAIL %s: %s\n' "$OP" "$1"
  exit 1
}

# cleanup: removes the temp file on every exit path. Reached only through the EXIT trap.
# shellcheck disable=SC2317,SC2329
cleanup() {
  _status=$?
  if [ -n "$TMP" ]; then
    rm -f "$TMP"
  fi
  exit "$_status"
}

# need_file <path>: the path is a readable regular file, or the op fails.
need_file() {
  if [ ! -f "$1" ] || [ ! -r "$1" ]; then
    fail "cannot read $1"
  fi
}

# make_temp: a fresh temp file beside the page, given the page's mode by cp -p; its name is kept in TMP for the
# cleanup trap. The new content is later written into it with a redirect, which keeps that mode.
make_temp() {
  _mt_dir=${PAGE%/*}
  if [ -z "$_mt_dir" ]; then
    _mt_dir=/
  fi
  if [ "$_mt_dir" = "$PAGE" ]; then
    _mt_dir=.
  fi
  TMP=$(mktemp "$_mt_dir/.page-edit.XXXXXX") || fail "cannot create a temp file beside $PAGE"
  cp -p "$PAGE" "$TMP" || fail "cannot copy the mode of $PAGE"
}

# copy_over: moves the temp file over the page. Runs only after every check passed; the temp file is then the page
# and TMP is cleared so the cleanup trap leaves it alone.
copy_over() {
  mv "$TMP" "$PAGE" || fail "cannot write $PAGE"
  TMP=""
}

# count_page <file> <needle>: sets COUNT to the number of matches in the file and FIRST to the first matching line.
count_page() {
  _pair=$(NEEDLE="$2" awk "$COUNT_FUNCS"'{ c = count_in($0, ENVIRON["NEEDLE"]); total += c; if (c > 0 && first == 0) first = NR } END { print total + 0, first + 0 }' "$1") || fail "cannot read $1"
  COUNT=${_pair%% *}
  FIRST=${_pair#* }
}

# find_one <attr> <value> <what>: attr="value" occurs exactly once on the page; sets FIRST to its line. Fails with
# "<what> not found" or "<what> repeated" otherwise.
find_one() {
  count_page "$PAGE" "$1=\"$2\""
  if [ "$COUNT" -eq 0 ]; then
    fail "$3 not found"
  fi
  if [ "$COUNT" -gt 1 ]; then
    fail "$3 repeated"
  fi
}

# find_anchor <name>: id="<name>" occurs exactly once on the page; sets FIRST to its line. Fails otherwise.
find_anchor() {
  find_one id "$1" "anchor $1"
}

# need_absent <attr> <value> <reason>: attr="value" does not occur on the page, or the op fails with the reason.
need_absent() {
  count_page "$PAGE" "$1=\"$2\""
  if [ "$COUNT" -gt 0 ]; then
    fail "$3"
  fi
}

# pr_check: the pr key was given, and its value is digits only.
pr_check() {
  if [ "$PR_SEEN" -eq 0 ]; then
    fail "missing key pr"
  fi
  case "$PR" in
    '' | *[!0-9]*) fail "pr must be a number" ;;
  esac
}

# block_end <name> <start line>: sets BLOCK_END to the last line of the block that starts at the start line. The block
# ends at the first later line equal to the start line's indent plus its closing tag, or at the start line itself when
# that line holds as many closing tags of its tag as opening tags of that tag (and at least one). Fails when no such
# line exists.
block_end() {
  BLOCK_END=$(awk -v s="$2" "$INDENT_FUNC"'
# count_open: the opening tags <tag, each followed by a character that is not a letter or digit.
function count_open(line, tag,   n, rest, p, after) {
  n = 0
  rest = line
  while ((p = index(rest, "<" tag)) > 0) {
    after = substr(rest, p + length(tag) + 1, 1)
    if (after !~ /[A-Za-z0-9]/) n++
    rest = substr(rest, p + 1)
  }
  return n
}
# count_close: the occurrences of the closing tag text.
function count_close(line, close_tag,   n, rest, p) {
  n = 0
  rest = line
  while ((p = index(rest, close_tag)) > 0) {
    n++
    rest = substr(rest, p + length(close_tag))
  }
  return n
}
NR == s {
  ind = indent_of($0)
  tag = ""
  if (match($0, /<[A-Za-z][A-Za-z0-9]*/)) tag = substr($0, RSTART + 1, RLENGTH - 1)
  close_tag = "</" tag ">"
  closes = count_close($0, close_tag)
  if (closes > 0 && closes == count_open($0, tag)) {
    print NR
    exit
  }
  want = ind close_tag
  next
}
NR > s && $0 == want {
  print NR
  exit
}' "$PAGE") || fail "cannot read $PAGE"
  if [ -z "$BLOCK_END" ]; then
    fail "block $1 has no closing line"
  fi
}

# hide_one <id>: checks the id's card anchor and block end, and the context anchor when one is on the page, and adds
# the blocks to RANGES. An id seen before is skipped. A context anchor absent from the page leaves only the card block
# to remove, with a NOTE line after the OK line. Nothing is written here.
hide_one() {
  case "$SEEN" in
    *"$NL$1$NL"*) return 0 ;;
  esac
  SEEN="$SEEN$1$NL"
  find_anchor "$1"
  _h_card=$FIRST
  count_page "$PAGE" "id=\"c-$1\""
  if [ "$COUNT" -gt 1 ]; then
    fail "anchor c-$1 repeated"
  fi
  _h_ctx=$FIRST
  block_end "$1" "$_h_card"
  _h_card_end=$BLOCK_END
  RANGES="$RANGES $_h_card $_h_card_end"
  if [ "$COUNT" -eq 0 ]; then
    OUT="${OUT}OK hide: $1$NL"
    OUT="${OUT}NOTE hide: $1 has no context section$NL"
    return 0
  fi
  block_end "c-$1" "$_h_ctx"
  RANGES="$RANGES $_h_ctx $BLOCK_END"
  OUT="${OUT}OK hide: $1$NL"
}

# remove_ranges: writes the page without the lines of RANGES (pairs of first and last line, in one pass) into the
# temp file and moves it over the page.
remove_ranges() {
  make_temp
  RANGES="$RANGES" awk 'BEGIN { n = split(ENVIRON["RANGES"], r, " "); for (k = 1; k < n; k += 2) for (i = r[k] + 0; i <= r[k + 1] + 0; i++) skip[i] = 1 } !(NR in skip) { print }' "$PAGE" > "$TMP" || fail "cannot write a temp file beside $PAGE"
  copy_over
}

# hide_all: every id was checked while the input was read; removes the blocks in one pass and prints the OK lines.
hide_all() {
  if [ "$HIDE_COUNT" -eq 0 ]; then
    fail "missing key hide"
  fi
  remove_ranges
  printf '%s' "$OUT"
}

# add_card: checks the input and the page, then inserts the card (and context) and prints the OK line.
add_card() {
  if [ -z "$BEFORE" ]; then
    fail "missing key before"
  fi
  if [ -z "$CARD" ]; then
    fail "missing key card"
  fi
  CARD_IDS=$(printf '%s\n' "$CARD" | NEEDLE='id="' awk "$COUNT_FUNCS"'{ total += count_in($0, ENVIRON["NEEDLE"]) } END { print total + 0 }' -) || fail "cannot read the card"
  if [ "$CARD_IDS" -eq 0 ]; then
    fail "card has no id"
  fi
  if [ "$CARD_IDS" -gt 1 ]; then
    fail "card has more than one id"
  fi
  NEW_ID=$(CARD_TEXT="$CARD" awk "$COUNT_FUNCS"'BEGIN { print id_in(ENVIRON["CARD_TEXT"]) }') || fail "cannot read the card"
  if [ -z "$NEW_ID" ]; then
    fail "card has an empty id"
  fi
  find_anchor "$BEFORE"
  BEFORE_LINE=$FIRST
  need_absent id "$NEW_ID" "id $NEW_ID already on the page"
  CTX_LINE=0
  if [ -n "$CONTEXT" ]; then
    find_anchor "c-$BEFORE"
    CTX_LINE=$FIRST
    need_absent id "c-$NEW_ID" "id c-$NEW_ID already on the page"
    CTX_IDS=$(CTX_TEXT="$CONTEXT" awk "$COUNT_FUNCS"'BEGIN { print count_in(ENVIRON["CTX_TEXT"], "id=\"") + 0 }') || fail "cannot read the context"
    if [ "$CTX_IDS" -gt 1 ]; then
      fail "context has more than one id"
    fi
    if [ "$CTX_IDS" -eq 0 ]; then
      fail "context id must be c-$NEW_ID"
    fi
    CTX_ID=$(CTX_TEXT="$CONTEXT" awk "$COUNT_FUNCS"'BEGIN { print id_in(ENVIRON["CTX_TEXT"]) }') || fail "cannot read the context"
    if [ -z "$CTX_ID" ]; then
      fail "context has an empty id"
    fi
    if [ "$CTX_ID" != "c-$NEW_ID" ]; then
      fail "context id must be c-$NEW_ID"
    fi
  fi
  make_temp
  CARD_TEXT="$CARD" CTX_TEXT="$CONTEXT" awk -v n1="$BEFORE_LINE" -v n2="$CTX_LINE" "$INDENT_FUNC"'
NR == n1 { print indent_of($0) ENVIRON["CARD_TEXT"] } NR == n2 { print indent_of($0) ENVIRON["CTX_TEXT"] } { print }' "$PAGE" > "$TMP" || fail "cannot write a temp file beside $PAGE"
  copy_over
  if [ -n "$CONTEXT" ]; then
    printf 'OK add-card: %s before %s and context\n' "$NEW_ID" "$BEFORE"
  else
    printf 'OK add-card: %s before %s\n' "$NEW_ID" "$BEFORE"
  fi
}

# status_op: replaces the text of the one-line element that holds data-status="<label>" with "<label>: <text>". The
# opening tag is the one that holds the attribute; its closing tag is the element's own, on the same line. A line
# without that closing tag fails before the page is touched.
status_op() {
  if [ -z "$STATUS_LABEL" ]; then
    fail "missing key status"
  fi
  if [ -z "$STATUS_TEXT" ]; then
    fail "missing key text"
  fi
  find_one data-status "$STATUS_LABEL" "label $STATUS_LABEL"
  make_temp
  _so_rc=0
  # shellcheck disable=SC2097,SC2098 # the awk program reads STATUS_ATTR and STATUS_LABEL through ENVIRON, so the env-prefix form is intended.
  STATUS_ATTR="data-status=\"$STATUS_LABEL\"" STATUS_LABEL="$STATUS_LABEL" STATUS_TEXT="$STATUS_TEXT" awk -v n="$FIRST" "$COUNT_FUNCS"'
NR == n {
  p = first_in($0, ENVIRON["STATUS_ATTR"])
  rest = substr($0, p)
  g = index(rest, ">")
  if (g == 0) exit 3
  open_end = p + g - 1
  pre = substr($0, 1, p - 1)
  if (!match(pre, /<[A-Za-z][A-Za-z0-9]*[^<]*$/)) exit 3
  name = substr(pre, RSTART + 1)
  sub(/[^A-Za-z0-9].*$/, "", name)
  close_tag = "</" name ">"
  c = index(substr($0, open_end + 1), close_tag)
  if (c == 0) exit 3
  close_at = open_end + c
  print substr($0, 1, open_end) ENVIRON["STATUS_LABEL"] ": " ENVIRON["STATUS_TEXT"] substr($0, close_at)
  next
}
{ print }' "$PAGE" > "$TMP" || _so_rc=$?
  if [ "$_so_rc" -eq 3 ]; then
    fail "label $STATUS_LABEL has no closing tag on its line"
  fi
  if [ "$_so_rc" -ne 0 ]; then
    fail "cannot write a temp file beside $PAGE"
  fi
  copy_over
  printf 'OK status: %s\n' "$STATUS_LABEL"
}

# ready_add: inserts the Ready to merge entry for pr directly below the first line after the ready anchor that opens
# a ul element (<ul followed by a space, a tab or >). The search ends at the first later line holding <section or <h2.
ready_add() {
  pr_check
  if [ -z "$ENTRY" ]; then
    fail "missing key entry"
  fi
  need_absent data-pr "$PR" "pr $PR already listed"
  find_anchor ready
  _ra_ul=$(awk -v a="$FIRST" 'NR > a && /<section|<h2/ { exit } NR > a && $0 ~ /<ul[[:space:]>]/ { print NR; exit }' "$PAGE") || fail "cannot read $PAGE"
  if [ -z "$_ra_ul" ]; then
    fail "no list after anchor ready"
  fi
  make_temp
  PR_NUM="$PR" ENTRY_HTML="$ENTRY" awk -v n="$_ra_ul" "$INDENT_FUNC"'
{ print }
NR == n {
  ind = indent_of($0)
  print ind "  <li data-pr=\"" ENVIRON["PR_NUM"] "\">" ENVIRON["ENTRY_HTML"] "</li>"
}' "$PAGE" > "$TMP" || fail "cannot write a temp file beside $PAGE"
  copy_over
  printf 'OK ready-add: %s\n' "$PR"
}

# ready_remove: removes the block of the Ready to merge entry for pr, found with the hide block rule.
ready_remove() {
  pr_check
  find_one data-pr "$PR" "pr $PR"
  block_end "$PR" "$FIRST"
  RANGES="$FIRST $BLOCK_END"
  remove_ranges
  printf 'OK ready-remove: %s\n' "$PR"
}

[ "$#" -eq 3 ] || usage
OP=$1
case "$OP" in
  add-card | hide | status | ready-add | ready-remove) ;;
  *) usage ;;
esac
PAGE=$2
IN=$3
trap 'cleanup' EXIT
trap 'exit 1' HUP INT TERM
need_file "$PAGE"
need_file "$IN"
if LC_ALL=C grep -q "$CR" "$IN"; then
  fail "input has a carriage return"
fi
if LC_ALL=C grep -q "[^$TAB -~]" "$IN"; then
  fail "input has a non-ASCII character"
fi

# Read the input: split each line at its first "=". The page is not touched until every line has been checked.
while IFS= read -r LINE || [ -n "$LINE" ]; do
  case "$LINE" in
    *=*) ;;
    *) continue ;;
  esac
  KEY=${LINE%%=*}
  VAL=${LINE#*=}
  case "$OP:$KEY" in
    add-card:before) BEFORE=$VAL ;;
    add-card:card) CARD=$VAL ;;
    add-card:context) CONTEXT=$VAL ;;
    hide:hide)
      HIDE_COUNT=$((HIDE_COUNT + 1))
      hide_one "$VAL"
      ;;
    status:status) STATUS_LABEL=$VAL ;;
    status:text) STATUS_TEXT=$VAL ;;
    ready-add:pr | ready-remove:pr)
      PR=$VAL
      PR_SEEN=1
      ;;
    ready-add:entry) ENTRY=$VAL ;;
  esac
done < "$IN"

case "$OP" in
  add-card) add_card ;;
  hide) hide_all ;;
  status) status_op ;;
  ready-add) ready_add ;;
  ready-remove) ready_remove ;;
esac
exit 0
