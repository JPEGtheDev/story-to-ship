#!/bin/sh
# page-edit.sh <op> <page file> <input file>
# Edits the owner question page (built from references/owner-questions-template.html) in place. Ops now: add-card and
# hide. The ops status, ready-add and ready-remove are added by a later change; until then they are usage errors.
# The input file holds key=value lines, each split at its first "="; a key the op does not read is ignored.
#   add-card: before=<id> card=<html> [context=<html>]
#     card is one line of HTML holding exactly one id attribute, id="<id>". It is inserted directly above the line
#     that holds id="<before>", with that line's indent. context, when given, is one line of HTML inserted directly
#     above the line that holds id="c-<before>", with that line's indent.
#   hide: hide=<id> (repeatable)
#     The card block is the line that holds id="<id>" through the first later line equal to that line's indent plus
#     the closing tag of the element that line opens, or that line alone when it also holds that closing tag. The
#     context block is the same for id="c-<id>". Both blocks are removed. An id given twice is removed once.
# An anchor is id="<value>" where the text before it is the start of the line, a space or a tab (so data-id="..." and
# href="#..." do not count). add-card needs the before anchor to occur exactly once; hide needs each id and c-<id> to
# occur exactly once.
# Output: on success one line per op: "OK add-card: <id> before <before>" (with " and context" when context was given),
# or one "OK hide: <id>" line per distinct id, in the order first given. On any failure exactly one line,
# "FAIL <op>: <reason>", on stdout, exit 1, and the page is not changed. A page or input that is not a readable regular
# file is a FAIL line too. Input bytes other than printable ASCII and tab fail the op.
# Exit codes: 0 all OK, 1 a FAIL, 2 a usage error (usage on stderr, nothing on stdout).
# Everything is checked before anything is written. The result is built in a temp file made with mktemp in the page's
# directory, given the page's mode by cp -p, and moved over the page with mv only when every check passed; the temp
# file is removed on every exit that has not moved it.
# Tools: sh, sed, awk, grep, mktemp, cp, mv, rm, and cmp. No other command is used.
NL='
'
TAB=$(printf '\t')
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
HIDE_COUNT=0
SEEN="$NL"
RANGES=""
OUT=""
COUNT=0
FIRST=0
BLOCK_END=""
BEFORE_LINE=0
CTX_LINE=0

# COUNT_FUNCS: awk function that counts the matches of a needle in one line. A match counts when the text before it is
# the start of the line, a space or a tab.
COUNT_FUNCS='
function count_in(line, needle,   rest, offset, p, abs, pre, n) {
  n = 0
  rest = line
  offset = 0
  while ((p = index(rest, needle)) > 0) {
    abs = offset + p
    if (abs == 1) {
      n++
    } else {
      pre = substr(line, abs - 1, 1)
      if (pre == " " || pre == "\t") n++
    }
    rest = substr(line, abs + 1)
    offset = abs
  }
  return n
}'

# usage: the usage line to stderr, exit 2.
usage() {
  printf 'usage: page-edit.sh <add-card|hide> <page file> <input file>\n' >&2
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

# find_anchor <name>: id="<name>" occurs exactly once on the page; sets FIRST to its line. Fails otherwise.
find_anchor() {
  count_page "$PAGE" "id=\"$1\""
  if [ "$COUNT" -eq 0 ]; then
    fail "anchor $1 not found"
  fi
  if [ "$COUNT" -gt 1 ]; then
    fail "anchor $1 repeated"
  fi
}

# need_absent <name> <reason>: id="<name>" does not occur on the page, or the op fails with the reason.
need_absent() {
  count_page "$PAGE" "id=\"$1\""
  if [ "$COUNT" -gt 0 ]; then
    fail "$2"
  fi
}

# block_end <name> <start line>: sets BLOCK_END to the last line of the block that starts at the start line. The block
# ends at the first later line equal to the start line's indent plus its closing tag, or at the start line itself when
# that line also holds the closing tag. Fails when no such line exists.
block_end() {
  BLOCK_END=$(awk -v s="$2" '
NR == s {
  ind = $0
  sub(/[^[:blank:]].*$/, "", ind)
  tag = ""
  if (match($0, /<[A-Za-z][A-Za-z0-9]*/)) tag = substr($0, RSTART + 1, RLENGTH - 1)
  close_tag = "</" tag ">"
  if (index($0, close_tag) > 0) {
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

# hide_one <id>: checks the id's card and context anchors and block ends, and adds both blocks to RANGES. An id seen
# before is skipped. Nothing is written here.
hide_one() {
  case "$SEEN" in
    *"$NL$1$NL"*) return 0 ;;
  esac
  SEEN="$SEEN$1$NL"
  find_anchor "$1"
  _h_card=$FIRST
  find_anchor "c-$1"
  _h_ctx=$FIRST
  block_end "$1" "$_h_card"
  _h_card_end=$BLOCK_END
  block_end "c-$1" "$_h_ctx"
  RANGES="$RANGES $_h_card $_h_card_end $_h_ctx $BLOCK_END"
  OUT="${OUT}OK hide: $1$NL"
}

# hide_all: every id was checked while the input was read; removes the blocks in one pass and prints the OK lines.
hide_all() {
  if [ "$HIDE_COUNT" -eq 0 ]; then
    fail "missing key hide"
  fi
  make_temp
  RANGES="$RANGES" awk 'BEGIN { n = split(ENVIRON["RANGES"], r, " "); for (k = 1; k < n; k += 2) for (i = r[k] + 0; i <= r[k + 1] + 0; i++) skip[i] = 1 } !(NR in skip) { print }' "$PAGE" > "$TMP" || fail "cannot write a temp file beside $PAGE"
  copy_over
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
  NEW_ID=$(printf '%s\n' "$CARD" | sed 's/.*[[:blank:]]id="\([^"]*\)".*/\1/')
  find_anchor "$BEFORE"
  BEFORE_LINE=$FIRST
  need_absent "$NEW_ID" "id $NEW_ID already on the page"
  CTX_LINE=0
  if [ -n "$CONTEXT" ]; then
    find_anchor "c-$BEFORE"
    CTX_LINE=$FIRST
    need_absent "c-$NEW_ID" "id c-$NEW_ID already on the page"
  fi
  make_temp
  CARD_TEXT="$CARD" CTX_TEXT="$CONTEXT" awk -v n1="$BEFORE_LINE" -v n2="$CTX_LINE" 'function indent_of(s) { sub(/[^[:blank:]].*$/, "", s); return s } NR == n1 { print indent_of($0) ENVIRON["CARD_TEXT"] } NR == n2 { print indent_of($0) ENVIRON["CTX_TEXT"] } { print }' "$PAGE" > "$TMP" || fail "cannot write a temp file beside $PAGE"
  copy_over
  if [ -n "$CONTEXT" ]; then
    printf 'OK add-card: %s before %s and context\n' "$NEW_ID" "$BEFORE"
  else
    printf 'OK add-card: %s before %s\n' "$NEW_ID" "$BEFORE"
  fi
}

[ "$#" -eq 3 ] || usage
OP=$1
case "$OP" in
  add-card | hide) ;;
  *) usage ;;
esac
PAGE=$2
IN=$3
trap 'cleanup' EXIT
trap 'exit 1' HUP INT TERM
need_file "$PAGE"
need_file "$IN"
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
  if [ "$OP" = add-card ]; then
    case "$KEY" in
      before) BEFORE=$VAL ;;
      card) CARD=$VAL ;;
      context) CONTEXT=$VAL ;;
    esac
  else
    case "$KEY" in
      hide)
        HIDE_COUNT=$((HIDE_COUNT + 1))
        hide_one "$VAL"
        ;;
    esac
  fi
done < "$IN"

if [ "$OP" = add-card ]; then
  add_card
else
  hide_all
fi
exit 0
