#!/usr/bin/env bash
# check-markers.sh -- asserts fixed-string presence/absence of pinned DoD
# canon oracle markers (see ../../skills/defining-done/references/DOD_TEMPLATE.md
# Section C) in a captured fixture-run output file.
#
# Usage: check-markers.sh <output-file> [--require '<literal>']... [--forbid '<literal>']...
#   --require LITERAL  assert LITERAL is present in output-file (grep -F)
#   --forbid LITERAL   assert LITERAL is absent from output-file (grep -F)
# At least one --require/--forbid flag is required.
#
# Fail loud by design (this repo's postmortem on silent gate loops): every
# failure path -- missing argument, unreadable file, zero assertion flags,
# an unknown flag, a failed assertion -- exits nonzero. Assertions are
# decided on grep's exit status directly, never on captured stdout.

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

TOTAL=0
PASS=0

for lit in "${REQUIRES[@]}"; do
  TOTAL=$((TOTAL + 1))
  if grep -qF -- "$lit" "$FILE"; then
    echo "PASS require '$lit'"
    PASS=$((PASS + 1))
  else
    echo "FAIL require '$lit'"
  fi
done

for lit in "${FORBIDS[@]}"; do
  TOTAL=$((TOTAL + 1))
  if grep -qF -- "$lit" "$FILE"; then
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
