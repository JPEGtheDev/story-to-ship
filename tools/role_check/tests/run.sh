#!/bin/sh
# Generated-fixture harness for role-check.sh.
# Each case is a git repo built under tests/generated/ (never committed) and checked
# by the detector. Usage: sh tools/role_check/tests/run.sh
# ROLE_CHECK=<path> points the harness at another detector (used to prove it can fail).
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
export LC_ALL=C.UTF-8 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

ROOT=$(cd "$(dirname "$0")/.." && pwd) || exit 2
SCRIPT=${ROLE_CHECK:-$ROOT/role-check.sh}
GEN=$ROOT/tests/generated
rm -rf "$GEN"
mkdir -p "$GEN" || exit 2

# git_commit <dir> <message>: commit with a fixed identity and no signing.
git_commit() {
  git -C "$1" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false commit -q -m "$2" </dev/null
}

# write_base <dir>: the base commit content shared by every case.
write_base() {
  mkdir -p "$1/src" "$1/tests" || return 1
  printf '%s\n' 'int f(void){return 1;}' > "$1/src/foo.c" || return 1
  printf '%s\n' 'assert(f()==1);' 'assert(f()!=0);' 'assert(f()<2);' > "$1/tests/foo_test.c" || return 1
}

# make_case <case> <change-kind> <path>
#   change: prepend a comment line to <path>
#   append: add a line at the end of <path>
#   add:    create <path> as a new file
#   The base commit is written first; the role change is the second commit.
make_case() {
  dir=$GEN/$1
  git init -q -b main "$dir" || exit 2
  write_base "$dir" || exit 2
  git -C "$dir" add -A || exit 2
  git_commit "$dir" base || exit 2
  case $2 in
    change) { printf '%s\n' '/* changed */'; cat "$dir/$3"; } > "$dir/$3.tmp" && mv "$dir/$3.tmp" "$dir/$3" || exit 2 ;;
    append) printf '%s\n' 'assert(f()>0);' >> "$dir/$3" || exit 2 ;;
    add)    printf '%s\n' 'assert(f()==1);' > "$dir/$3" || exit 2 ;;
    *) echo "unknown change kind: $2" >&2; exit 2 ;;
  esac
  git -C "$dir" add -A || exit 2
  git_commit "$dir" "role change" || exit 2
}

# run_case <case> <role> <expected-exit> <expected-text>
run_case() {
  out=$(cd "$GEN/$1" && sh "$SCRIPT" "$2" HEAD 2>&1 </dev/null)
  got=$?
  if [ "$got" -ne "$3" ]; then
    printf 'FAIL %s: expected exit %s got %s\n%s\n' "$1" "$3" "$got" "$out"
    failed=$((failed + 1))
  elif ! printf '%s\n' "$out" | grep -qF -e "$4"; then
    printf 'FAIL %s: output lacks expected text: %s\n%s\n' "$1" "$4" "$out"
    failed=$((failed + 1))
  else
    printf 'ok %s\n' "$1"
  fi
  cases=$((cases + 1))
}

# Case table: name|role|change-kind|path|expected-exit|expected-text
# To add a case, add one row; the make_case and run_case helpers do the rest.
cases=0
failed=0
while IFS='|' read -r name role kind path code text; do
  make_case "$name" "$kind" "$path"
  run_case "$name" "$role" "$code" "$text"
done <<'CASES'
tw-bad|test-writer|change|src/foo.c|1|VIOLATION test-writer touched non-test file
tw-ok|test-writer|append|tests/foo_test.c|0|OK test-writer
pm-bad|pass-maker|change|tests/foo_test.c|1|VIOLATION pass-maker touched test file
pm-ok|pass-maker|change|src/foo.c|0|OK pass-maker
rf-bad|refactorer|add|tests/new_test.c|1|VIOLATION refactorer added, deleted or renamed a test file
rf-ok|refactorer|change|src/foo.c|0|OK refactorer
CASES

printf '%s cases, %s failed\n' "$cases" "$failed"
if [ "$failed" -eq 0 ]; then
  exit 0
fi
exit 1
