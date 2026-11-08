#!/bin/sh
# verify-command-check.sh <prompt file>: flags the verification-command forms a script can find.
# Prints "VIOLATION line <N>: <form>" for each match, N counting lines from 1; exits 1 when any
# violation was printed, 0 when none was, and 2 on a usage error.
# Form echo: the line has the word echo and a file redirect (">" or ">>"). A ">" directly preceded
# by a digit (as in 2>) or directly followed by & (as in >&) is not a file redirect.
# Form digit-count: the line has grep, a digit pattern ([0-9], [[:digit:]] or \d), and a count step
# (wc or grep -c), and no whole-word number from zero to twelve (case-insensitive).
# A line may produce both violations; each is printed.
# Usage: sh verify-command-check.sh <prompt file>

if [ "$#" -ne 1 ]; then
  printf '%s\n' 'usage: sh verify-command-check.sh <prompt file>' >&2
  exit 2
fi
if [ ! -f "$1" ] || [ ! -r "$1" ]; then
  printf '%s\n' "error: not a readable file: $1" >&2
  exit 2
fi

# is_echo_redirect <line>: true when the line has the word echo and a file redirect.
is_echo_redirect() {
  printf '%s\n' "$1" | grep -qE '(^|[^[:alnum:]_])echo([^[:alnum:]_]|$)' || return 1
  printf '%s\n' "$1" | grep -qE '(^|[^0-9])>>?[^&]'
}

# is_digit_count <line>: true when the line matches the digit-count form.
is_digit_count() {
  printf '%s\n' "$1" | grep -qE '(^|[^[:alnum:]_])grep([^[:alnum:]_]|$)' || return 1
  printf '%s\n' "$1" | grep -qF -e '[0-9]' -e '[[:digit:]]' -e '\d' || return 1
  printf '%s\n' "$1" | grep -qE '(^|[^[:alnum:]_])wc([^[:alnum:]_]|$)' ||
    printf '%s\n' "$1" | grep -qF 'grep -c' || return 1
  if printf '%s\n' "$1" | grep -qiE '(^|[^[:alnum:]_])(zero|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)([^[:alnum:]_]|$)'; then
    return 1
  fi
  return 0
}

violations=0
n=0
while IFS= read -r line || [ -n "$line" ]; do
  n=$((n + 1))
  if is_echo_redirect "$line"; then
    printf 'VIOLATION line %s: echo\n' "$n"
    violations=$((violations + 1))
  fi
  if is_digit_count "$line"; then
    printf 'VIOLATION line %s: digit-count\n' "$n"
    violations=$((violations + 1))
  fi
done < "$1"

if [ "$violations" -gt 0 ]; then
  exit 1
fi
exit 0
