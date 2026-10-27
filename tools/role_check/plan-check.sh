#!/bin/sh
# plan-check.sh <planfile>: every plan entry must carry exactly one "loop: three-role" or
# "loop: single" marker line before the next header or end of file.
# A header is a column-0 "Todo N" or "Task N" (optionally after "#"s and spaces) followed by
# a non-alphanumeric character or end of line. Lines inside a column-0 fence (three or more
# backticks or tildes, closed by the same character at least as long) are ignored; an
# unclosed fence runs to end of file. A trailing CR is stripped from every line.
# Exit 0 when every entry has one marker, 1 when any entry has none or more than one,
# 2 on usage, read or no-entry errors.

if [ "$#" -ne 1 ]; then
  echo 'usage: plan-check.sh <planfile>' >&2
  exit 2
fi
plan=$1
if [ ! -f "$plan" ] || [ ! -r "$plan" ]; then
  printf 'cannot read plan: %s\n' "$plan" >&2
  exit 2
fi

cr=$(printf '\r')

# check_entry: report the current entry unless it has exactly one marker.
check_entry() {
  if [ "$marked" -eq 0 ]; then
    printf 'VIOLATION %s has no loop: marker\n' "$header"
    violations=$((violations + 1))
  elif [ "$marked" -gt 1 ]; then
    printf 'VIOLATION %s has more than one loop: marker\n' "$header"
    violations=$((violations + 1))
  fi
}

entries=0
violations=0
header=
marked=0
fchar=
flen=0
while IFS= read -r line || [ -n "$line" ]; do
  line=${line%"$cr"}
  if [ -n "$fchar" ]; then
    # Inside a fence: only a line of the opener character, at least as long, closes it.
    case $line in
      ''|*[!"$fchar"]*) ;;
      *) if [ "${#line}" -ge "$flen" ]; then fchar=; fi ;;
    esac
    continue
  fi
  case $line in
    '```'*|'~~~'*)
      fchar=${line%"${line#?}"}
      run=${line%%[!"$fchar"]*}
      flen=${#run}
      continue ;;
  esac
  if printf '%s\n' "$line" | grep -Eq '^(#+ +)?(Todo|Task) [0-9]+([^[:alnum:]]|$)'; then
    if [ "$entries" -gt 0 ]; then
      check_entry
    fi
    entries=$((entries + 1))
    header=${line#"${line%%[! #]*}"}
    marked=0
  elif printf '%s\n' "$line" | grep -Eq '^loop: (three-role|single)( |$)'; then
    marked=$((marked + 1))
  fi
done < "$plan"

if [ "$entries" -eq 0 ]; then
  printf 'no entries in plan: %s\n' "$plan" >&2
  exit 2
fi
check_entry
if [ "$violations" -gt 0 ]; then
  exit 1
fi
printf 'OK plan-check: %s entries\n' "$entries"
exit 0
