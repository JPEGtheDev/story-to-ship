#!/usr/bin/env bash
set -eu
cat > greet.sh <<'SCRIPT'
#!/bin/sh
printf 'Good evening, Sam\n'
printf 'Have a nice day\n'
SCRIPT
cat > check.sh <<'SCRIPT'
#!/bin/sh
out=$(sh greet.sh)
line1=$(printf '%s\n' "$out" | sed -n 1p)
line2=$(printf '%s\n' "$out" | sed -n 2p)
pass=0
fail=0
if [ "$line1" = "Good morning, Sam" ]; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  echo "FAIL line 1: got '$line1'"
fi
if [ "$line2" = "Have a nice day" ]; then
  pass=$((pass + 1))
else
  fail=$((fail + 1))
  echo "FAIL line 2: got '$line2'"
fi
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
SCRIPT
