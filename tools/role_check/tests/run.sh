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
# --allow-empty lets the empty change kind commit nothing.
git_commit() {
  git -C "$1" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false commit -q --allow-empty -m "$2" </dev/null
}

# write_base <dir>: the base commit content shared by every case.
write_base() {
  mkdir -p "$1/src" "$1/tests" || return 1
  printf '%s\n' 'int f(void){return 1;}' > "$1/src/foo.c" || return 1
  printf '%s\n' 'assert(f()==1);' 'assert(f()!=0);' 'assert(f()<2);' > "$1/tests/foo_test.c" || return 1
}

# make_case <case> <change-kind> <path>
#   change:   prepend a comment line to <path>
#   append:   add a line at the end of <path>
#   add:      create <path> as a new file (its parent directory is created if missing)
#   empty:    no file change; the role commit is empty
#   skipline: append an it.skip(...) line to <path>
#   csskip:   append a [Ignore] line to <path>
#   drop:     delete the first two lines of <path>
#   swap:     replace the first line of <path> with an assertTrue(1) line
#   tabfile:  create a file whose name is src/a<TAB>b.c (<path> is unused)
#   The path column may use %b octal escapes with a leading zero (for example caf\0303\0251); it is decoded first.
#   The base commit is written first; the role change is the second commit.
make_case() {
  dir=$GEN/$1
  dest=$(printf '%b' "$3")
  git init -q -b main "$dir" || exit 2
  write_base "$dir" || exit 2
  git -C "$dir" add -A || exit 2
  git_commit "$dir" base || exit 2
  case $2 in
    change)   { printf '%s\n' '/* changed */'; cat "$dir/$dest"; } > "$dir/$dest.tmp" && mv "$dir/$dest.tmp" "$dir/$dest" || exit 2 ;;
    append)   printf '%s\n' 'assert(f()>0);' >> "$dir/$dest" || exit 2 ;;
    add)      mkdir -p "$(dirname "$dir/$dest")" && printf '%s\n' 'assert(f()==1);' > "$dir/$dest" || exit 2 ;;
    empty)    ;;
    skipline) printf '%s\n' "it.skip('x', () => {});" >> "$dir/$dest" || exit 2 ;;
    csskip)   printf '%s\n' '[Ignore]' >> "$dir/$dest" || exit 2 ;;
    drop)     tail -n +3 "$dir/$dest" > "$dir/$dest.tmp" && mv "$dir/$dest.tmp" "$dir/$dest" || exit 2 ;;
    swap)     { printf '%s\n' 'assertTrue(1);'; tail -n +2 "$dir/$dest"; } > "$dir/$dest.tmp" && mv "$dir/$dest.tmp" "$dir/$dest" || exit 2 ;;
    tabfile)  tab=$(printf '\t'); printf '%s\n' 'assert(f()==1);' > "$dir/src/a${tab}b.c" || exit 2 ;;
    *) echo "unknown change kind: $2" >&2; exit 2 ;;
  esac
  git -C "$dir" add -A || exit 2
  git_commit "$dir" "role change" || exit 2
}

# run_case <case> <role> <expected-exit> <expected-text> [<test-path ERE>]
run_case() {
  if [ -n "$5" ]; then
    out=$(cd "$GEN/$1" && sh "$SCRIPT" "$2" HEAD "$5" 2>&1 </dev/null)
  else
    out=$(cd "$GEN/$1" && sh "$SCRIPT" "$2" HEAD 2>&1 </dev/null)
  fi
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

# Case table: name|role|change-kind|path|expected-exit|expected-text|test-path-ere (optional)
# To add a case, add one row; the make_case and run_case helpers do the rest.
# Lines starting with # are comments. A -MISS row is a documented miss the detector cannot catch.
cases=0
failed=0
while IFS='|' read -r name role kind path code text ere; do
  case $name in '#'*|'') continue ;; esac
  make_case "$name" "$kind" "$path"
  run_case "$name" "$role" "$code" "$text" "$ere"
done <<'CASES'
tw-bad|test-writer|change|src/foo.c|1|VIOLATION test-writer touched non-test file
tw-ok|test-writer|append|tests/foo_test.c|0|OK test-writer
pm-bad|pass-maker|change|tests/foo_test.c|1|VIOLATION pass-maker touched test file
pm-ok|pass-maker|change|src/foo.c|0|OK pass-maker
rf-bad|refactorer|add|tests/new_test.c|1|VIOLATION refactorer added, deleted or renamed a test file
rf-ok|refactorer|change|src/foo.c|0|OK refactorer
space-ok|pass-maker|add|src/my file.py|0|OK pass-maker
nonascii-ok|test-writer|add|tests/caf\0303\0251_test.py|0|OK test-writer
java-test-ok|test-writer|add|src/FooTest.java|0|OK test-writer
cs-test-ok|test-writer|add|src/FooTests.cs|0|OK test-writer
java-main-bad|test-writer|add|src/Foo.java|1|VIOLATION test-writer touched non-test file
unknown-role|tester|change|src/foo.c|2|unknown role: tester
empty-tw|test-writer|empty|-|1|changes nothing
skip-tw|test-writer|skipline|tests/foo_test.c|1|added a skip marker
# Documented miss: swapping one assertion for another keeps the assertion count equal, so only a reviewer can judge it.
weaken-rf-MISS|refactorer|swap|tests/foo_test.c|0|OK refactorer
drop-rf|refactorer|drop|tests/foo_test.c|1|removed 2 assertion lines and added 0
# Documented miss: an empty refactor commit is caught only by the dispatcher's commit count, not by the detector.
empty-rf-MISS|refactorer|empty|-|0|OK refactorer
# Documented miss: the skip scan has no C# attribute pattern, so a [Ignore] line passes; a reviewer must judge it.
csharp-skip-MISS|test-writer|csskip|tests/foo_test.c|0|OK test-writer
ere-override-ok|test-writer|add|check/foo.sh|0|OK test-writer|^check/
ere-none-bad|test-writer|add|check/foo.sh|1|VIOLATION test-writer touched non-test file
default-word-ok|test-writer|append|tests/foo_test.c|0|OK test-writer|default
bad-ere|pass-maker|change|src/foo.c|2|bad test-path pattern|(
tab-path|pass-maker|tabfile|-|2|needs C-quoting
CASES

# plan_write <file> <line>...: write a plan file, one argument per line.
plan_write() {
  mkdir -p "$(dirname "$1")" || exit 2
  plan_file=$1
  shift
  printf '%s\n' "$@" > "$plan_file" || exit 2
}

# plan_run <name> <plan-file> <expected-exit> <expected-text>: plan-check.sh cases.
plan_run() {
  out=$(sh "$ROOT/plan-check.sh" "$2" 2>&1 </dev/null)
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

# Plan-marker checker cases: plan-check.sh <planfile>.
PLANS=$GEN/plans
plan_write "$PLANS/plan-ok.md" 'Todo 1: first' 'loop: single -- reason: prose' 'Files: a' 'Depends on: none' 'Todo 2: second' 'loop: three-role -- reason: code' 'Depends on: Todo 1'
plan_run plan-ok "$PLANS/plan-ok.md" 0 'OK plan-check: 2 entries'
plan_write "$PLANS/plan-task-ok.md" 'Task 1: x' 'loop: single -- reason: y' 'Files: a'
plan_run plan-task-ok "$PLANS/plan-task-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/plan-first-bare.md" 'Todo 1: first' 'Files: a' 'Todo 2: second' 'loop: single -- reason: y'
plan_run plan-first-bare "$PLANS/plan-first-bare.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write "$PLANS/plan-last-bare.md" 'Todo 1: first' 'loop: single -- reason: y' 'Todo 2: second' 'Files: b'
plan_run plan-last-bare "$PLANS/plan-last-bare.md" 1 'VIOLATION Todo 2: second has no loop: marker'
plan_write "$PLANS/plan-bad-form.md" 'Todo 1: first' 'loop: both -- reason: y'
plan_run plan-bad-form "$PLANS/plan-bad-form.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write "$PLANS/plan-marker-before-header.md" 'loop: single -- reason: y' 'Todo 1: first' 'Files: a'
plan_run plan-marker-before-header "$PLANS/plan-marker-before-header.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write "$PLANS/plan-no-entries.md" 'just some text'
plan_run plan-no-entries "$PLANS/plan-no-entries.md" 2 'no entries in plan'
plan_run plan-missing-file "$PLANS/does-not-exist.md" 2 'cannot read plan'

printf '%s cases, %s failed\n' "$cases" "$failed"
if [ "$failed" -eq 0 ]; then
  exit 0
fi
exit 1
