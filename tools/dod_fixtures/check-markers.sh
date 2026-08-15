#!/usr/bin/env bash
# check-markers.sh -- checks for the presence or absence of pinned
# Definition of Done (DoD) marker lines (see the defining-done skill's
# Definition of Done canon template reference, Section C, "Consumer
# notes") in a captured fixture-run output file.
#
# Matching rule: a marker literal counts as PRESENT only when some line
# of the output file starts with it -- a fixed-string prefix match at
# line start, with no regex interpretation of the marker text. A line
# that merely mentions the marker text somewhere after its start (for
# example, in a prose sentence describing what did or did not happen)
# does not count as an occurrence. This distinguishes a genuine marker
# emission (always written at the start of its own line) from a
# transcript line that happens to discuss the marker in passing.
#
# Usage: check-markers.sh <output-file> [--require '<literal>']... [--forbid '<literal>']...
#   --require LITERAL  assert some line in output-file starts with LITERAL
#   --forbid LITERAL   assert no line in output-file starts with LITERAL
# At least one --require/--forbid flag is required.
#
# Fail loud by design: this script checks a captured output file for
# exact marker strings, so every failure path -- missing argument,
# unreadable file, zero assertion flags, an unknown flag, a failed
# assertion -- exits nonzero. That makes a run's pass/fail outcome
# machine-checkable rather than something a person has to eyeball from
# scrollback. Assertions are decided on the line-start match directly,
# never on captured stdout.

usage() {
  echo "Usage: $(basename "$0") <output-file> [--require '<literal>']... [--forbid '<literal>']..." >&2
}

if [[ $# -lt 1 ]]; then
  usage
  exit 2
fi

FILE="$1"
shift

if [[ ! -f "$FILE" || ! -r "$FILE" ]]; then
  echo "$(basename "$0"): cannot read output file (not a readable regular file): $FILE" >&2
  exit 2
fi

REQUIRES=()
FORBIDS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --require)
      if [[ $# -lt 2 ]]; then
        echo "$(basename "$0"): --require needs an argument" >&2
        exit 2
      fi
      REQUIRES+=("$2")
      shift 2
      ;;
    --forbid)
      if [[ $# -lt 2 ]]; then
        echo "$(basename "$0"): --forbid needs an argument" >&2
        exit 2
      fi
      FORBIDS+=("$2")
      shift 2
      ;;
    *)
      echo "$(basename "$0"): unknown flag: $1" >&2
      exit 2
      ;;
  esac
done

if [[ "${#REQUIRES[@]}" -eq 0 && "${#FORBIDS[@]}" -eq 0 ]]; then
  echo "$(basename "$0"): at least one --require or --forbid flag is required" >&2
  exit 2
fi

# line_starts_with_literal LITERAL FILE -- true (exit 0) if some line of
# FILE begins with LITERAL, matched as a fixed string (no regex
# interpretation), false (exit 1) otherwise. Implemented with awk's
# index(), which finds the position of the first fixed-string occurrence
# of LITERAL in a line -- position 1 means the line starts with it.
line_starts_with_literal() {
  local literal="$1" file="$2"
  awk -v m="$literal" 'index($0, m) == 1 { found = 1; exit } END { exit !found }' "$file"
}

TOTAL=0
PASS=0

for lit in "${REQUIRES[@]}"; do
  TOTAL=$((TOTAL + 1))
  if line_starts_with_literal "$lit" "$FILE"; then
    echo "PASS require '$lit'"
    PASS=$((PASS + 1))
  else
    echo "FAIL require '$lit'"
  fi
done

for lit in "${FORBIDS[@]}"; do
  TOTAL=$((TOTAL + 1))
  if line_starts_with_literal "$lit" "$FILE"; then
    echo "FAIL forbid '$lit'"
  else
    echo "PASS forbid '$lit'"
    PASS=$((PASS + 1))
  fi
done

if [[ "$PASS" -eq "$TOTAL" ]]; then
  echo "RESULT: PASS ($PASS/$TOTAL)"
  exit 0
else
  echo "RESULT: FAIL ($PASS/$TOTAL)"
  exit 1
fi
