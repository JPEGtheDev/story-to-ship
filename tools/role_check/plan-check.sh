#!/bin/sh
# plan-check.sh <planfile>: every plan entry (a "Todo N:" or "Task N:" header) must carry
# a "loop: three-role" or "loop: single" marker before the next header or end of file.
# Exit 0 when all entries are marked, 1 when any entry is unmarked, 2 on usage or read errors.

if [ "$#" -ne 1 ]; then
  echo 'usage: plan-check.sh <planfile>' >&2
  exit 2
fi
plan=$1
if [ ! -f "$plan" ] || [ ! -r "$plan" ]; then
  printf 'cannot read plan: %s\n' "$plan" >&2
  exit 2
fi

# Keep only header and marker lines, numbered, in file order.
found=$(grep -nE -e '^(Todo|Task) [0-9]+:' -e '^loop: (three-role|single)( |$)' -- "$plan")

# report_unmarked <header>: print the violation for an entry that has no marker.
report_unmarked() {
  printf 'VIOLATION %s has no loop: marker\n' "$1"
  violations=$((violations + 1))
}

entries=0
violations=0
header=
marked=0
while IFS= read -r entry; do
  text=${entry#*:}
  case $text in
    '') ;;
    loop:*)
      marked=1 ;;
    *)
      if [ "$entries" -gt 0 ] && [ "$marked" -eq 0 ]; then
        report_unmarked "$header"
      fi
      entries=$((entries + 1))
      header=$text
      marked=0 ;;
  esac
done <<EOF
$found
EOF

if [ "$entries" -eq 0 ]; then
  printf 'no entries in plan: %s\n' "$plan" >&2
  exit 2
fi
if [ "$marked" -eq 0 ]; then
  report_unmarked "$header"
fi
if [ "$violations" -gt 0 ]; then
  exit 1
fi
printf 'OK plan-check: %s entries\n' "$entries"
exit 0
