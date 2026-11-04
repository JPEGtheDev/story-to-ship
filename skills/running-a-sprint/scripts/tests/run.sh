#!/bin/sh
# Runs every tests/*.test.sh file with sh and prints one line per file plus a summary.
# Exits 1 when a test file fails or when no *.test.sh file exists.
# Usage: sh skills/running-a-sprint/scripts/tests/run.sh
DIR=$(cd "$(dirname "$0")" && pwd) || exit 2

total=0
failed=0
for t in "$DIR"/*.test.sh; do
  [ -f "$t" ] || continue
  total=$((total + 1))
  if sh "$t"; then
    printf 'PASS %s\n' "$(basename "$t")"
  else
    printf 'FAIL %s\n' "$(basename "$t")"
    failed=$((failed + 1))
  fi
done

if [ "$total" -eq 0 ]; then
  printf 'run.sh: no *.test.sh files in %s\n' "$DIR"
  exit 1
fi
printf 'run.sh: %s test files, %s failed\n' "$total" "$failed"
if [ "$failed" -ne 0 ]; then
  exit 1
fi
exit 0
