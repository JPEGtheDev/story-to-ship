#!/bin/sh
# Generated-fixture harness for role-check.sh and plan-check.sh.
# Role cases are git repos built under tests/generated/ (never committed) and checked
# by the detector; plan cases are plan files written under tests/generated/plans/.
# Usage: sh tools/role_check/tests/run.sh
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
space-tw-ok|test-writer|add|src/my file_test.py|0|OK test-writer
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
# Documented miss: an empty refactor commit passes the detector; the dispatcher's commit count catches it only when the refactorer reported no refactor needed, otherwise the reviewer judges it.
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

# plan_write_crlf <file> <line>...: like plan_write, but every line ends in CR LF.
plan_write_crlf() {
  mkdir -p "$(dirname "$1")" || exit 2
  plan_file=$1
  shift
  printf '%s\r\n' "$@" > "$plan_file" || exit 2
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

# Header shapes: a header is a column-0 "Todo N" or "Task N" (optionally after "#"s and spaces) followed by a non-alphanumeric character or end of line.
plan_write "$PLANS/hdr-nocolon-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Todo 2 second' 'Files: b'
plan_run hdr-nocolon-bad "$PLANS/hdr-nocolon-bad.md" 1 'VIOLATION Todo 2 second has no loop: marker'
plan_write "$PLANS/hdr-heading-bad.md" '## Todo 1: first' 'Files: a'
plan_run hdr-heading-bad "$PLANS/hdr-heading-bad.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write "$PLANS/hdr-heading-ok.md" '### Task 1: x' 'loop: single -- reason: y'
plan_run hdr-heading-ok "$PLANS/hdr-heading-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/hdr-h1-ok.md" '# Todo 12: x' 'loop: single -- reason: y'
plan_run hdr-h1-ok "$PLANS/hdr-h1-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/hdr-1a.md" 'Todo 1a x'
plan_run hdr-1a "$PLANS/hdr-1a.md" 2 'no entries in plan'

# Fences: a column-0 run of three or more backticks or tildes opens a fence; lines inside it are ignored.
plan_write "$PLANS/fence-marker-bt.md" 'Todo 1: first' '```' 'loop: single -- reason: y' '```'
plan_run fence-marker-bt "$PLANS/fence-marker-bt.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write "$PLANS/fence-marker-tilde.md" 'Todo 1: first' '~~~' 'loop: single -- reason: y' '~~~'
plan_run fence-marker-tilde "$PLANS/fence-marker-tilde.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write "$PLANS/fence-info-string.md" 'Todo 1: first' '```sh' 'loop: single -- reason: y' '```'
plan_run fence-info-string "$PLANS/fence-info-string.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write "$PLANS/fence-header-ignored.md" 'Todo 1: first' 'loop: single -- reason: y' '```' 'Todo 9: sample' '```'
plan_run fence-header-ignored "$PLANS/fence-header-ignored.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/fence-unclosed.md" 'Todo 1: first' '```' 'loop: single -- reason: y'
plan_run fence-unclosed "$PLANS/fence-unclosed.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write "$PLANS/fence-only-header.md" '```' 'Todo 1: first' '```'
plan_run fence-only-header "$PLANS/fence-only-header.md" 2 'no entries in plan'
plan_write "$PLANS/fence-mismatch-closer.md" 'Todo 1: first' '```' '~~~' 'loop: single -- reason: y'
plan_run fence-mismatch-closer "$PLANS/fence-mismatch-closer.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write "$PLANS/fence-prev-entry.md" 'Todo 1: a' '```' 'loop: single -- reason: y' '```' 'Todo 2: b' 'loop: single -- reason: y'
plan_run fence-prev-entry "$PLANS/fence-prev-entry.md" 1 'VIOLATION Todo 1: a has no loop: marker'
# Documented miss: an indented fence is not recognised, so a column-0 marker inside it counts.
plan_write "$PLANS/fence-indented-MISS.md" 'Todo 1: first' '  ```' 'loop: single' '  ```'
plan_run fence-indented-MISS "$PLANS/fence-indented-MISS.md" 0 'OK plan-check: 1 entries'

# CRLF: a CR LF file is judged exactly like an LF file, and printed text has no CR.
plan_write_crlf "$PLANS/crlf-bare-ok.md" 'Todo 1: first' 'loop: single'
plan_run crlf-bare-ok "$PLANS/crlf-bare-ok.md" 0 'OK plan-check: 1 entries'
plan_write_crlf "$PLANS/crlf-unmarked.md" 'Todo 1: first' 'Files: a'
plan_run crlf-unmarked "$PLANS/crlf-unmarked.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write_crlf "$PLANS/crlf-fence.md" 'Todo 1: first' '```' 'loop: single -- reason: y' '```'
plan_run crlf-fence "$PLANS/crlf-fence.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write_crlf "$PLANS/crlf-heading-ok.md" '## Todo 1: first' 'loop: single'
plan_run crlf-heading-ok "$PLANS/crlf-heading-ok.md" 0 'OK plan-check: 1 entries'

# No final newline: the last line still counts as a marker.
printf 'Todo 1: first\nloop: single -- reason: y' > "$PLANS/no-trailing-newline.md" || exit 2
plan_run no-trailing-newline "$PLANS/no-trailing-newline.md" 0 'OK plan-check: 1 entries'

# Duplicate markers: an entry must carry exactly one marker.
plan_write "$PLANS/dup-diff.md" 'Todo 1: first' 'loop: single -- reason: x' 'loop: three-role -- reason: y'
plan_run dup-diff "$PLANS/dup-diff.md" 1 'VIOLATION Todo 1: first has more than one loop: marker'
plan_write "$PLANS/dup-same.md" 'Todo 1: first' 'loop: single -- reason: y' 'loop: single -- reason: y'
plan_run dup-same "$PLANS/dup-same.md" 1 'VIOLATION Todo 1: first has more than one loop: marker'
plan_write "$PLANS/dup-three.md" 'Todo 1: first' 'loop: single -- reason: y' 'loop: single -- reason: y' 'loop: three-role -- reason: y'
plan_run dup-three "$PLANS/dup-three.md" 1 'VIOLATION Todo 1: first has more than one loop: marker'
plan_write "$PLANS/dup-middle.md" 'Todo 1: a' 'loop: single -- reason: y' 'loop: single -- reason: y' 'Todo 2: b' 'loop: single -- reason: y'
plan_run dup-middle "$PLANS/dup-middle.md" 1 'VIOLATION Todo 1: a has more than one loop: marker'
plan_write "$PLANS/valid-plus-invalid.md" 'Todo 1: first' 'loop: single -- reason: y' 'loop: both -- reason: y'
plan_run valid-plus-invalid "$PLANS/valid-plus-invalid.md" 0 'OK plan-check: 1 entries'

# Fence closers: a closer may carry leading or trailing spaces or tabs, but still needs the opener character at least as many times.
plan_write "$PLANS/fence-closer-trailing-space.md" 'Todo 1: a' 'loop: single -- reason: y' '```' 'code' '``` ' 'Todo 2: b' 'Files: x'
plan_run fence-closer-trailing-space "$PLANS/fence-closer-trailing-space.md" 1 'VIOLATION Todo 2: b has no loop: marker'
plan_write "$PLANS/fence-closer-indented.md" 'Todo 1: a' 'loop: single -- reason: y' '```' 'code' '  ```' 'Todo 2: b' 'Files: x'
plan_run fence-closer-indented "$PLANS/fence-closer-indented.md" 1 'VIOLATION Todo 2: b has no loop: marker'
plan_write "$PLANS/fence-closer-longer.md" 'Todo 1: first' '~~~' 'x' '~~~~~' 'loop: single -- reason: y'
plan_run fence-closer-longer "$PLANS/fence-closer-longer.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/fence-closer-shorter.md" 'Todo 1: first' '````' 'loop: single -- reason: y' '```' 'z'
plan_run fence-closer-shorter "$PLANS/fence-closer-shorter.md" 1 'VIOLATION Todo 1: first has no loop: marker'

# Bare header at end of line: "Todo N" with nothing after the number is still a header.
plan_write "$PLANS/hdr-bare-eol.md" 'Todo 1: a' 'loop: single -- reason: y' 'Todo 3'
plan_run hdr-bare-eol "$PLANS/hdr-bare-eol.md" 1 'VIOLATION Todo 3 has no loop: marker'

# Empty file: zero bytes, no entries.
: > "$PLANS/empty-file.md" || exit 2
plan_run empty-file "$PLANS/empty-file.md" 2 'no entries in plan'

printf '%s cases, %s failed\n' "$cases" "$failed"
if [ "$failed" -eq 0 ]; then
  exit 0
fi
exit 1
