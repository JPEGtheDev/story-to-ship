#!/usr/bin/env bash
set -eu
if [ -e .git ] || [ -e .claude-plugin ]; then echo "refusing: not an empty scratch directory" >&2; exit 1; fi
mkdir -p reports
for n in 01 02 03 04 05 06 07 08 09 10 11 12; do
  f="reports/q3-$n.csv"
  if [ "$n" = 04 ] || [ "$n" = 09 ]; then
    printf '\n' > "$f"
  else
    printf 'id,region,amount\n' > "$f"
  fi
  for r in 1 2 3; do
    printf '%s-%s,north,%s.50\n' "$n" "$r" "$((r * 100))" >> "$f"
  done
done
