#!/bin/sh
# usage: role-check.sh <role> <commit> [test-path ERE]
# role: test-writer | pass-maker | refactorer. The commit is one role commit; its parent is the base.
# Exit 0 = boundary held, 1 = violation, 2 = input this script cannot judge (check by hand).
# Needs git and a POSIX grep. The test-path ERE argument is optional; "default" means omitted.
role=$1; commit=$2; test_re=$3
[ "$test_re" = default ] && test_re=
if [ -n "$test_re" ]; then printf 'x\n' | grep -Eiq -e "$test_re"; [ $? -le 1 ] || { echo "bad test-path pattern: $test_re" >&2; exit 2; }; fi
dir_re='(^|/)(tests?|__tests__|spec|testdata|fixtures)/|(^|/)test_[^/]*$|(^|/)conftest\.py$|_(test|spec)\.[^/]*$|\.(spec|test)\.[^/]*$'
camel_re='[a-z0-9](Test|Tests|Spec)\.[^/]*$'
case $role in test-writer | pass-maker | refactorer) ;; *) echo "unknown role: $role" >&2; exit 2 ;; esac
git rev-parse --verify -q "$commit^{commit}" >/dev/null || { echo "bad commit: $commit" >&2; exit 2; }
git rev-parse --verify -q "$commit^" >/dev/null || { echo "root commit has no parent to compare with" >&2; exit 2; }
if git rev-parse --verify -q "$commit^2" >/dev/null; then echo "merge commit: check by hand" >&2; exit 2; fi
base="$commit^"
status=$(git -c core.quotePath=false diff --no-color --no-ext-diff --name-status "$base" "$commit") || exit 2
if printf '%s\n' "$status" | grep -Eq "$(printf '\t')\""; then echo "a path needs C-quoting (tab, quote or backslash): check by hand" >&2; exit 2; fi
is_test() {
  if [ -n "$test_re" ]; then printf '%s\n' "$1" | grep -Eiq -e "$test_re"; return; fi
  printf '%s\n' "$1" | grep -Eiq "$dir_re" || printf '%s\n' "$1" | grep -Eq "$camel_re"
}
bad=0
if [ -z "$status" ] && [ "$role" != refactorer ]; then echo "VIOLATION $role commit changes nothing"; bad=1; fi
tab=$(printf '\t')
tests_changed=""
while IFS="$tab" read -r code path rest; do
  [ -n "$code" ] || continue
  for p in "$path" "$rest"; do
    [ -n "$p" ] || continue
    if is_test "$p"; then t=1; else t=0; fi
    case $role in
      test-writer) [ "$t" = 1 ] || { echo "VIOLATION test-writer touched non-test file: $code $p"; bad=1; } ;;
      pass-maker)  [ "$t" = 0 ] || { echo "VIOLATION pass-maker touched test file: $code $p"; bad=1; } ;;
      refactorer)  if [ "$t" = 1 ] && [ "$code" != M ]; then echo "VIOLATION refactorer added, deleted or renamed a test file: $code $p"; bad=1; fi ;;
    esac
    if [ "$t" = 1 ] && [ "$code" != D ]; then tests_changed="$tests_changed
$p"; fi
  done
done <<LIST
$status
LIST
if [ "$role" != pass-maker ]; then
  # heuristic: added lines in changed test files that disable a test, and (refactorer) net loss of assertions
  skip_re='(^|[^[:alnum:]_])(it|test|describe)\.(skip|only|todo)\(|(^|[^[:alnum:]_])(xit|xtest|xdescribe)\(|(^|[^[:alnum:]_])(pytest\.)?skip\(|@pytest\.mark\.(skip|xfail)|@(Ignore|Disabled)|#\[ignore\]|t\.Skip(Now)?\(|DISABLED_|expectedFailure|\.only\('
  assert_re='assert|expect|EXPECT_|ASSERT_|CHECK'
  added=0; removed=0
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    d=$(git -c core.quotePath=false diff --no-color --no-ext-diff "$base" "$commit" -- "$f")
    hit=$(printf '%s\n' "$d" | grep -E '^\+' | grep -vE '^\+\+\+' | grep -E "$skip_re" || true)
    if [ -n "$hit" ]; then echo "VIOLATION $role added a skip marker in $f: $hit"; bad=1; fi
    a=$(printf '%s\n' "$d" | grep -E '^\+' | grep -vE '^\+\+\+' | grep -Eic "$assert_re" || true)
    r=$(printf '%s\n' "$d" | grep -E '^-' | grep -vE '^---' | grep -Eic "$assert_re" || true)
    added=$((added + a)); removed=$((removed + r))
  done <<FILES
$tests_changed
FILES
  if [ "$role" = refactorer ] && [ "$removed" -gt "$added" ]; then echo "VIOLATION refactorer removed $removed assertion lines and added $added"; bad=1; fi
fi
[ "$bad" = 0 ] && echo "OK $role"
exit "$bad"
