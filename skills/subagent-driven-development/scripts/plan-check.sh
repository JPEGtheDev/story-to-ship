#!/bin/sh
# plan-check.sh <planfile>: every plan entry must carry exactly one "loop: three-role" or
# "loop: single" marker line before the next header or end of file, a "Files:" line and a
# "Depends on:" line at column 0.
# A header is a column-0 "Todo N" or "Task N" (optionally after "#"s and spaces) followed by
# a non-alphanumeric character or end of line. Lines inside a column-0 fence (three or more
# backticks or tildes, closed by the same character at least as long) are ignored; an
# unclosed fence runs to end of file. A trailing CR is stripped from every line.
# A Files line is filled by non-blank text after the colon, or by an indented list item line
# ("  - text") that follows it before the next column-0 non-blank line (blank lines allowed).
# A Depends on line is filled only by non-blank text after the colon. An entry with several
# Files or Depends on lines is filled when any of them is filled; an entry whose lines are all
# empty reports "has an empty ... line", and one with no such line reports "has no ... line".
# Placeholder check: every physical line outside a fence (headers and lines before the first
# header included) is scanned after the CR strip. The whole words TBD and TODO (case-sensitive;
# a letter, digit or underscore next to the word is not a boundary) and the substrings
# "implement later", "fill in details" and "Similar to Task" are placeholders. One violation
# is reported per line, naming the first match in that order, as "line <N>" with N counting
# every physical line of the file from 1.
# Non-ASCII check: every physical line outside a fence is scanned the same way; a line holding
# any byte from 128 to 255 is reported as "line <N>: non-ASCII character", after any placeholder
# violation for that line. Bytes 0 to 127 (tabs, control characters) are never flagged.
# Token budget check: a plan of 8 or more entries must hold at least one line outside a fence
# that starts at column 0 and reads exactly "Token budget: todos=<digits> minimum-dispatches=<digits>
# tokens-per-dispatch=<digits or unmeasured>" (single spaces, no sign, nothing after the last
# field). Only the format is checked. Missing it is reported once, after the per-entry
# messages, as "VIOLATION plan has <N> entries and no Token budget line".
# Exit 0 when every entry passes all checks, 1 when any entry fails one, 2 on usage, read or
# no-entry errors.

if [ "$#" -ne 1 ]; then
  echo 'usage: plan-check.sh <planfile>' >&2
  exit 2
fi
plan=$1
if [ ! -f "$plan" ] || [ ! -r "$plan" ]; then
  printf 'cannot read plan: %s\n' "$plan" >&2
  exit 2
fi

# Byte-based matching: the header class [^[:alnum:]] must not depend on the caller's locale.
LC_ALL=C
export LC_ALL

cr=$(printf '\r')
tab=$(printf '\t')
high=$(printf '\200')
top=$(printf '\377')

# trim_blanks <text>: set trimmed to text without leading and trailing spaces and tabs.
trim_blanks() {
  trimmed=$1
  trimmed=${trimmed#"${trimmed%%[!" $tab"]*}"}
  trimmed=${trimmed%"${trimmed##*[!" $tab"]}"}
}

# reset_entry: clear the per-entry state; the caller sets header.
reset_entry() {
  marked=0
  files_seen=0
  files_filled=0
  files_pending=0
  deps_seen=0
  deps_filled=0
}

# check_field <label> <seen> <filled>: report a missing or empty field line.
check_field() {
  if [ "$3" -eq 0 ]; then
    if [ "$2" -eq 0 ]; then
      printf 'VIOLATION %s has no %s line\n' "$header" "$1"
    else
      printf 'VIOLATION %s has an empty %s line\n' "$header" "$1"
    fi
    violations=$((violations + 1))
  fi
}

# placeholder_of <line>: set matched to the first placeholder in the line, empty when none.
placeholder_of() {
  matched=
  case $1 in
    *TBD*|*TODO*)
      for word in TBD TODO; do
        if printf '%s\n' "$1" | grep -Eq "(^|[^A-Za-z0-9_])$word([^A-Za-z0-9_]|\$)"; then
          matched=$word
          return
        fi
      done ;;
  esac
  case $1 in
    *'implement later'*) matched='implement later' ;;
    *'fill in details'*) matched='fill in details' ;;
    *'Similar to Task'*) matched='Similar to Task' ;;
  esac
}

# has_non_ascii <line>: succeed when the line holds a byte from 128 to 255.
has_non_ascii() {
  printf '%s\n' "$1" | grep -q "[$high-$top]"
}

# check_entry: report each failed check of the current entry.
check_entry() {
  if [ "$marked" -eq 0 ]; then
    printf 'VIOLATION %s has no loop: marker\n' "$header"
    violations=$((violations + 1))
  elif [ "$marked" -gt 1 ]; then
    printf 'VIOLATION %s has more than one loop: marker\n' "$header"
    violations=$((violations + 1))
  fi
  check_field 'Files:' "$files_seen" "$files_filled"
  check_field 'Depends on:' "$deps_seen" "$deps_filled"
}

entries=0
violations=0
budget_seen=0
header=
reset_entry
fchar=
flen=0
lineno=0
while IFS= read -r line || [ -n "$line" ]; do
  lineno=$((lineno + 1))
  line=${line%"$cr"}
  if [ -n "$fchar" ]; then
    # Inside a fence: a closer is the opener character, at least as long, after leading and
    # trailing spaces and tabs are stripped from a copy of the line.
    trim_blanks "$line"
    case $trimmed in
      ''|*[!"$fchar"]*) ;;
      *) if [ "${#trimmed}" -ge "$flen" ]; then fchar=; fi ;;
    esac
    continue
  fi
  # A column-0 non-blank line closes a pending empty Files line.
  case $line in
    [!" $tab"]*) files_pending=0 ;;
  esac
  case $line in
    '```'*|'~~~'*)
      fchar=${line%"${line#?}"}
      run=${line%%[!"$fchar"]*}
      flen=${#run}
      continue ;;
  esac
  placeholder_of "$line"
  if [ -n "$matched" ]; then
    printf 'VIOLATION line %s: placeholder text %s\n' "$lineno" "$matched"
    violations=$((violations + 1))
  fi
  if has_non_ascii "$line"; then
    printf 'VIOLATION line %s: non-ASCII character\n' "$lineno"
    violations=$((violations + 1))
  fi
  case $line in
    'Token budget:'*)
      if printf '%s\n' "$line" | grep -Eq '^Token budget: todos=[0-9]+ minimum-dispatches=[0-9]+ tokens-per-dispatch=([0-9]+|unmeasured)$'; then
        budget_seen=1
      fi ;;
  esac
  if printf '%s\n' "$line" | grep -Eq '^(#+ +)?(Todo|Task) [0-9]+([^[:alnum:]]|$)'; then
    if [ "$entries" -gt 0 ]; then
      check_entry
    fi
    entries=$((entries + 1))
    header=${line#"${line%%[! #]*}"}
    reset_entry
  elif printf '%s\n' "$line" | grep -Eq '^loop: (three-role|single)( |$)'; then
    marked=$((marked + 1))
  else
    case $line in
      'Files:'*)
        files_seen=1
        trim_blanks "${line#Files:}"
        if [ -n "$trimmed" ]; then
          files_filled=1
        else
          files_pending=1
        fi ;;
      'Depends on:'*)
        deps_seen=1
        trim_blanks "${line#'Depends on:'}"
        if [ -n "$trimmed" ]; then
          deps_filled=1
        fi ;;
      *)
        if [ "$files_pending" -eq 1 ] &&
          printf '%s\n' "$line" | grep -Eq '^[[:blank:]]+-[[:blank:]]+[^[:blank:]]'; then
          files_filled=1
        fi ;;
    esac
  fi
done < "$plan"

if [ "$entries" -eq 0 ]; then
  printf 'no entries in plan: %s\n' "$plan" >&2
  exit 2
fi
check_entry
if [ "$entries" -ge 8 ] && [ "$budget_seen" -eq 0 ]; then
  printf 'VIOLATION plan has %s entries and no Token budget line\n' "$entries"
  violations=$((violations + 1))
fi
if [ "$violations" -gt 0 ]; then
  exit 1
fi
printf 'OK plan-check: %s entries\n' "$entries"
exit 0
