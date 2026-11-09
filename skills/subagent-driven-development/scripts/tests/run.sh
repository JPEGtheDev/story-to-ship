#!/bin/sh
# Generated-fixture harness for role-check.sh and plan-check.sh.
# Role cases are git repos built under tests/generated/ (never committed) and checked
# by the detector; plan cases are plan files written under tests/generated/plans/.
# Usage: sh skills/subagent-driven-development/scripts/tests/run.sh
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

# plan_run_exact <name> <plan-file> <expected-exit> <expected-output>: like plan_run, but the
# whole output must equal the expected text, so an extra line or a trailing CR fails.
plan_run_exact() {
  out=$(sh "$ROOT/plan-check.sh" "$2" 2>&1 </dev/null)
  got=$?
  if [ "$got" -ne "$3" ]; then
    printf 'FAIL %s: expected exit %s got %s\n%s\n' "$1" "$3" "$got" "$out"
    failed=$((failed + 1))
  elif [ "$out" != "$4" ]; then
    printf 'FAIL %s: output is not exactly: %s\n%s\n' "$1" "$4" "$out"
    failed=$((failed + 1))
  else
    printf 'ok %s\n' "$1"
  fi
  cases=$((cases + 1))
}

# Plan-marker checker cases: plan-check.sh <planfile>.
PLANS=$GEN/plans
plan_write "$PLANS/plan-ok.md" 'Todo 1: first' 'loop: single -- reason: prose' 'Files: a' 'Depends on: none' 'Todo 2: second' 'loop: three-role -- reason: code' 'Files: a' 'Depends on: Todo 1'
plan_run plan-ok "$PLANS/plan-ok.md" 0 'OK plan-check: 2 entries'
plan_write "$PLANS/plan-task-ok.md" 'Task 1: x' 'loop: single -- reason: y' 'Files: a' 'Depends on: none'
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
plan_write "$PLANS/hdr-heading-ok.md" '### Task 1: x' 'loop: single -- reason: y' 'Files: a' 'Depends on: none'
plan_run hdr-heading-ok "$PLANS/hdr-heading-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/hdr-h1-ok.md" '# Todo 12: x' 'loop: single -- reason: y' 'Files: a' 'Depends on: none'
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
plan_write "$PLANS/fence-header-ignored.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' '```' 'Todo 9: sample' '```'
plan_run fence-header-ignored "$PLANS/fence-header-ignored.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/fence-unclosed.md" 'Todo 1: first' '```' 'loop: single -- reason: y'
plan_run fence-unclosed "$PLANS/fence-unclosed.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write "$PLANS/fence-only-header.md" '```' 'Todo 1: first' '```'
plan_run fence-only-header "$PLANS/fence-only-header.md" 2 'no entries in plan'
plan_write "$PLANS/fence-mismatch-closer.md" 'Todo 1: first' '```' '~~~' 'loop: single -- reason: y'
plan_run fence-mismatch-closer "$PLANS/fence-mismatch-closer.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write "$PLANS/fence-prev-entry.md" 'Todo 1: a' '```' 'loop: single -- reason: y' '```' 'Todo 2: b' 'loop: single -- reason: y'
plan_run fence-prev-entry "$PLANS/fence-prev-entry.md" 1 'VIOLATION Todo 1: a has no loop: marker'
# Documented miss: an indented fence is not recognized, so a column-0 marker inside it counts.
plan_write "$PLANS/fence-indented-MISS.md" 'Todo 1: first' 'Files: a' 'Depends on: none' '  ```' 'loop: single' '  ```'
plan_run fence-indented-MISS "$PLANS/fence-indented-MISS.md" 0 'OK plan-check: 1 entries'

# CRLF: a CR LF file is judged exactly like an LF file, and printed text has no CR.
plan_write_crlf "$PLANS/crlf-bare-ok.md" 'Todo 1: first' 'loop: single' 'Files: a' 'Depends on: none'
plan_run crlf-bare-ok "$PLANS/crlf-bare-ok.md" 0 'OK plan-check: 1 entries'
plan_write_crlf "$PLANS/crlf-unmarked.md" 'Todo 1: first' 'Files: a'
plan_run crlf-unmarked "$PLANS/crlf-unmarked.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write_crlf "$PLANS/crlf-fence.md" 'Todo 1: first' '```' 'loop: single -- reason: y' '```'
plan_run crlf-fence "$PLANS/crlf-fence.md" 1 'VIOLATION Todo 1: first has no loop: marker'
plan_write_crlf "$PLANS/crlf-heading-ok.md" '## Todo 1: first' 'loop: single' 'Files: a' 'Depends on: none'
plan_run crlf-heading-ok "$PLANS/crlf-heading-ok.md" 0 'OK plan-check: 1 entries'

# No final newline: the last line still counts as a marker.
printf 'Todo 1: first\nFiles: a\nDepends on: none\nloop: single -- reason: y' > "$PLANS/no-trailing-newline.md" || exit 2
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
plan_write "$PLANS/valid-plus-invalid.md" 'Todo 1: first' 'loop: single -- reason: y' 'loop: both -- reason: y' 'Files: a' 'Depends on: none'
plan_run valid-plus-invalid "$PLANS/valid-plus-invalid.md" 0 'OK plan-check: 1 entries'

# Fence closers: a closer may carry leading or trailing spaces or tabs, but still needs the opener character at least as many times.
plan_write "$PLANS/fence-closer-trailing-space.md" 'Todo 1: a' 'loop: single -- reason: y' '```' 'code' '``` ' 'Todo 2: b' 'Files: x'
plan_run fence-closer-trailing-space "$PLANS/fence-closer-trailing-space.md" 1 'VIOLATION Todo 2: b has no loop: marker'
plan_write "$PLANS/fence-closer-indented.md" 'Todo 1: a' 'loop: single -- reason: y' '```' 'code' '  ```' 'Todo 2: b' 'Files: x'
plan_run fence-closer-indented "$PLANS/fence-closer-indented.md" 1 'VIOLATION Todo 2: b has no loop: marker'
plan_write "$PLANS/fence-closer-longer.md" 'Todo 1: first' 'Files: a' 'Depends on: none' '~~~' 'x' '~~~~~' 'loop: single -- reason: y'
plan_run fence-closer-longer "$PLANS/fence-closer-longer.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/fence-closer-shorter.md" 'Todo 1: first' '````' 'loop: single -- reason: y' '```' 'z'
plan_run fence-closer-shorter "$PLANS/fence-closer-shorter.md" 1 'VIOLATION Todo 1: first has no loop: marker'

# Bare header at end of line: "Todo N" with nothing after the number is still a header.
plan_write "$PLANS/hdr-bare-eol.md" 'Todo 1: a' 'loop: single -- reason: y' 'Todo 3'
plan_run hdr-bare-eol "$PLANS/hdr-bare-eol.md" 1 'VIOLATION Todo 3 has no loop: marker'

# Empty file: zero bytes, no entries.
: > "$PLANS/empty-file.md" || exit 2
plan_run empty-file "$PLANS/empty-file.md" 2 'no entries in plan'

# Files: and Depends on: checks. Each fixture is otherwise valid (a loop marker plus the other line).
plan_write "$PLANS/files-missing-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Depends on: none'
plan_run files-missing-bad "$PLANS/files-missing-bad.md" 1 'VIOLATION Todo 1: first has no Files: line'
plan_write "$PLANS/files-spaces-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files:   ' 'Depends on: none'
plan_run files-spaces-bad "$PLANS/files-spaces-bad.md" 1 'VIOLATION Todo 1: first has an empty Files: line'
plan_write "$PLANS/files-empty-then-column0-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files:' 'Depends on: none'
plan_run files-empty-then-column0-bad "$PLANS/files-empty-then-column0-bad.md" 1 'VIOLATION Todo 1: first has an empty Files: line'
plan_write "$PLANS/files-blank-then-list-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files:' '' '  - a' 'Depends on: none'
plan_run files-blank-then-list-ok "$PLANS/files-blank-then-list-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/files-list-direct-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files:' '  - a' 'Depends on: none'
plan_run files-list-direct-ok "$PLANS/files-list-direct-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/files-inline-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none'
plan_run files-inline-ok "$PLANS/files-inline-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/files-col2-bad.md" 'Todo 1: first' 'loop: single -- reason: y' '  Files: a' 'Depends on: none'
plan_run files-col2-bad "$PLANS/files-col2-bad.md" 1 'VIOLATION Todo 1: first has no Files: line'
plan_write "$PLANS/files-fence-only-bad.md" 'Todo 1: first' 'loop: single -- reason: y' '```' 'Files: a' '```' 'Depends on: none'
plan_run files-fence-only-bad "$PLANS/files-fence-only-bad.md" 1 'VIOLATION Todo 1: first has no Files: line'
plan_write "$PLANS/files-two-lines-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files:' 'Files: a' 'Depends on: none'
plan_run files-two-lines-ok "$PLANS/files-two-lines-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/files-entry2-missing-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Todo 2: second' 'loop: single -- reason: y' 'Depends on: none'
plan_run files-entry2-missing-bad "$PLANS/files-entry2-missing-bad.md" 1 'VIOLATION Todo 2: second has no Files: line'
plan_write "$PLANS/files-before-header-bad.md" 'Files: a' 'Todo 1: first' 'loop: single -- reason: y' 'Depends on: none'
plan_run files-before-header-bad "$PLANS/files-before-header-bad.md" 1 'VIOLATION Todo 1: first has no Files: line'
plan_write_crlf "$PLANS/files-crlf-empty-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files:' 'Depends on: none'
plan_run files-crlf-empty-bad "$PLANS/files-crlf-empty-bad.md" 1 'VIOLATION Todo 1: first has an empty Files: line'
plan_write "$PLANS/depends-missing-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a'
plan_run depends-missing-bad "$PLANS/depends-missing-bad.md" 1 'VIOLATION Todo 1: first has no Depends on: line'
plan_write "$PLANS/depends-spaces-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on:   '
plan_run depends-spaces-bad "$PLANS/depends-spaces-bad.md" 1 'VIOLATION Todo 1: first has an empty Depends on: line'
plan_write "$PLANS/depends-col2-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' '  Depends on: none'
plan_run depends-col2-bad "$PLANS/depends-col2-bad.md" 1 'VIOLATION Todo 1: first has no Depends on: line'
plan_write "$PLANS/depends-fence-only-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' '```' 'Depends on: none' '```'
plan_run depends-fence-only-bad "$PLANS/depends-fence-only-bad.md" 1 'VIOLATION Todo 1: first has no Depends on: line'
plan_write "$PLANS/depends-entry2-missing-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Todo 2: second' 'loop: single -- reason: y' 'Files: a'
plan_run depends-entry2-missing-bad "$PLANS/depends-entry2-missing-bad.md" 1 'VIOLATION Todo 2: second has no Depends on: line'
plan_write "$PLANS/depends-before-header-bad.md" 'Depends on: none' 'Todo 1: first' 'loop: single -- reason: y' 'Files: a'
plan_run depends-before-header-bad "$PLANS/depends-before-header-bad.md" 1 'VIOLATION Todo 1: first has no Depends on: line'
plan_write "$PLANS/depends-none-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none'
plan_run depends-none-ok "$PLANS/depends-none-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/depends-todo1-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Todo 2: second' 'loop: single -- reason: y' 'Files: b' 'Depends on: Todo 1'
plan_run depends-todo1-ok "$PLANS/depends-todo1-ok.md" 0 'OK plan-check: 2 entries'
plan_write "$PLANS/depends-continuation-only-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on:' '  - Todo 1'
plan_run depends-continuation-only-bad "$PLANS/depends-continuation-only-bad.md" 1 'VIOLATION Todo 1: first has an empty Depends on: line'
plan_write_crlf "$PLANS/depends-crlf-both-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none'
plan_run depends-crlf-both-ok "$PLANS/depends-crlf-both-ok.md" 0 'OK plan-check: 1 entries'

# Placeholder checks: TBD and TODO as whole words (case-sensitive; a letter, digit or underscore
# directly before or after is no match), and the phrases "implement later", "fill in details"
# and "Similar to Task". Every physical line outside a fence is checked, and the line number
# counts fenced lines. One violation per line; the first match in the order TBD, TODO,
# implement later, fill in details, Similar to Task is reported.
plan_write "$PLANS/ph-tbd.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: TBD write the parser'
plan_run_exact ph-tbd "$PLANS/ph-tbd.md" 1 'VIOLATION line 5: placeholder text TBD'
plan_write "$PLANS/ph-todo.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: TODO wire the check'
plan_run_exact ph-todo "$PLANS/ph-todo.md" 1 'VIOLATION line 5: placeholder text TODO'
plan_write "$PLANS/ph-implement-later.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: implement later on'
plan_run_exact ph-implement-later "$PLANS/ph-implement-later.md" 1 'VIOLATION line 5: placeholder text implement later'
plan_write "$PLANS/ph-fill-in-details.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: fill in details here'
plan_run_exact ph-fill-in-details "$PLANS/ph-fill-in-details.md" 1 'VIOLATION line 5: placeholder text fill in details'
plan_write "$PLANS/ph-similar-to-task.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: Similar to Task 1 above'
plan_run_exact ph-similar-to-task "$PLANS/ph-similar-to-task.md" 1 'VIOLATION line 5: placeholder text Similar to Task'
plan_write "$PLANS/ph-header.md" 'Todo 1: TBD' 'loop: single -- reason: y' 'Files: a' 'Depends on: none'
plan_run_exact ph-header "$PLANS/ph-header.md" 1 'VIOLATION line 1: placeholder text TBD'
plan_write "$PLANS/ph-before-header.md" 'Notes: TODO check the spec' 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none'
plan_run_exact ph-before-header "$PLANS/ph-before-header.md" 1 'VIOLATION line 1: placeholder text TODO'
plan_write "$PLANS/ph-after-fence.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' '```' 'sample code' '```' 'Step: TBD after the fence'
plan_run_exact ph-after-fence "$PLANS/ph-after-fence.md" 1 'VIOLATION line 8: placeholder text TBD'
plan_write "$PLANS/ph-paren.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: (TBD) write it'
plan_run_exact ph-paren "$PLANS/ph-paren.md" 1 'VIOLATION line 5: placeholder text TBD'
plan_write "$PLANS/ph-colon.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: TBD: write it'
plan_run_exact ph-colon "$PLANS/ph-colon.md" 1 'VIOLATION line 5: placeholder text TBD'
plan_write "$PLANS/ph-hyphen-digit.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: TBD-1 write it'
plan_run_exact ph-hyphen-digit "$PLANS/ph-hyphen-digit.md" 1 'VIOLATION line 5: placeholder text TBD'
plan_write_crlf "$PLANS/ph-crlf.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: TODO write it'
plan_run_exact ph-crlf "$PLANS/ph-crlf.md" 1 'VIOLATION line 5: placeholder text TODO'
plan_write "$PLANS/ph-two-on-line.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: TBD and TODO here'
plan_run_exact ph-two-on-line "$PLANS/ph-two-on-line.md" 1 'VIOLATION line 5: placeholder text TBD'
plan_write "$PLANS/ph-lower-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: tbd write it'
plan_run ph-lower-ok "$PLANS/ph-lower-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/ph-underscore-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: TODO_TEMPLATES stays'
plan_run ph-underscore-ok "$PLANS/ph-underscore-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/ph-letter-before-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: xTBD stays'
plan_run ph-letter-before-ok "$PLANS/ph-letter-before-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/ph-digit-after-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: TBD2 stays'
plan_run ph-digit-after-ok "$PLANS/ph-digit-after-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/ph-fence-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' '```' 'implement later' 'fill in details' 'Similar to Task 2' 'TBD' 'TODO' '```'
plan_run ph-fence-ok "$PLANS/ph-fence-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/ph-valid-multi-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Todo 2: second' 'loop: three-role -- reason: y' 'Files: b' 'Depends on: Todo 1' 'Task 3: third' 'loop: single -- reason: y' 'Files: c' 'Depends on: Todo 2'
plan_run ph-valid-multi-ok "$PLANS/ph-valid-multi-ok.md" 0 'OK plan-check: 3 entries'
# Documented miss: an indented fence is not recognized, so its placeholder line is flagged (exit 1) although the author meant it as quoted text.
plan_write "$PLANS/ph-indented-fence-MISS.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' '  ```' 'Step: TBD inside an indented fence' '  ```'
plan_run_exact ph-indented-fence-MISS "$PLANS/ph-indented-fence-MISS.md" 1 'VIOLATION line 6: placeholder text TBD'

# Non-ASCII checks: a physical line outside a fence with any byte above 127 is one violation,
# numbered from 1 over every physical line (fenced lines included). Bytes are written as printf
# octal escapes so this file stays ASCII. Every entry carries a loop marker, Files: a and Depends on: none.
NA_EM=$(printf '\342\200\224')
NA_BYTE=$(printf '\377')
NA_BOM=$(printf '\357\273\277')
NA_TAB=$(printf '\t')
NA_CTL=$(printf '\001')
plan_write "$PLANS/na-step-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' "Step: write it $NA_EM parser"
plan_run_exact na-step-bad "$PLANS/na-step-bad.md" 1 'VIOLATION line 5: non-ASCII character'
plan_write "$PLANS/na-header-bad.md" "Todo 1: first $NA_EM second" 'loop: single -- reason: y' 'Files: a' 'Depends on: none'
plan_run_exact na-header-bad "$PLANS/na-header-bad.md" 1 'VIOLATION line 1: non-ASCII character'
plan_write "$PLANS/na-before-header-bad.md" "Notes: see $NA_EM draft" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none'
plan_run_exact na-before-header-bad "$PLANS/na-before-header-bad.md" 1 'VIOLATION line 1: non-ASCII character'
plan_write "$PLANS/na-after-fence-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' '```' 'code' '```' "Step: write it $NA_EM parser"
plan_run_exact na-after-fence-bad "$PLANS/na-after-fence-bad.md" 1 'VIOLATION line 8: non-ASCII character'
plan_write "$PLANS/na-lone-byte-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' "Step: caf$NA_BYTE latte"
plan_run_exact na-lone-byte-bad "$PLANS/na-lone-byte-bad.md" 1 'VIOLATION line 5: non-ASCII character'
plan_write "$PLANS/na-bom-bad.md" "${NA_BOM}Plan notes" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none'
plan_run_exact na-bom-bad "$PLANS/na-bom-bad.md" 1 'VIOLATION line 1: non-ASCII character'
plan_write "$PLANS/na-two-on-line-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' "Step: $NA_EM and $NA_BYTE here"
plan_run_exact na-two-on-line-bad "$PLANS/na-two-on-line-bad.md" 1 'VIOLATION line 5: non-ASCII character'
plan_write_crlf "$PLANS/na-crlf-bad.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' "Step: write it $NA_EM parser"
plan_run_exact na-crlf-bad "$PLANS/na-crlf-bad.md" 1 'VIOLATION line 5: non-ASCII character'
plan_write "$PLANS/na-ascii-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: plain ASCII text only'
plan_run na-ascii-ok "$PLANS/na-ascii-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/na-tab-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' "Step:${NA_TAB}write it"
plan_run na-tab-ok "$PLANS/na-tab-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/na-control-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' "Step: a${NA_CTL}b"
plan_run na-control-ok "$PLANS/na-control-ok.md" 0 'OK plan-check: 1 entries'
plan_write_crlf "$PLANS/na-crlf-ascii-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Step: plain ASCII text only'
plan_run na-crlf-ascii-ok "$PLANS/na-crlf-ascii-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/na-fence-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' '```' "sample $NA_EM text" '```'
plan_run na-fence-ok "$PLANS/na-fence-ok.md" 0 'OK plan-check: 1 entries'
plan_write "$PLANS/na-multi-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' 'Todo 2: second' 'loop: three-role -- reason: y' 'Files: b' 'Depends on: Todo 1' '```' 'code sample' '```' 'Task 3: third' 'loop: single -- reason: y' 'Files: c' 'Depends on: Todo 2'
plan_run na-multi-ok "$PLANS/na-multi-ok.md" 0 'OK plan-check: 3 entries'
plan_write "$PLANS/ph-opener-unscanned-ok.md" 'Todo 1: first' 'loop: single -- reason: y' 'Files: a' 'Depends on: none' '```TODO'"$NA_EM" 'x' '```'
plan_run ph-opener-unscanned-ok "$PLANS/ph-opener-unscanned-ok.md" 0 'OK plan-check: 1 entries'

# Token budget checks: a plan of 8 or more entries needs a line outside a fence that matches
# "Token budget: todos=<digits> minimum-dispatches=<digits> tokens-per-dispatch=<digits|unmeasured>".
# pe_line <text>: print one line in the plan's line ending (pe_eol is lf or crlf).
pe_line() {
  if [ "$pe_eol" = crlf ]; then
    printf '%s\r\n' "$1"
  else
    printf '%s\n' "$1"
  fi
}

# plan_entries <file> <count> <kind> <eol> [preamble-line]...: write a plan with the preamble lines
# first, then <count> valid entries. kind is Todo, Task, or mix (first half Todo, second half Task).
# Each entry carries a loop marker, Files: a and Depends on: none.
plan_entries() {
  mkdir -p "$(dirname "$1")" || exit 2
  pe_file=$1
  pe_count=$2
  pe_kind=$3
  pe_eol=$4
  shift 4
  {
    for pe_pre in "$@"; do
      pe_line "$pe_pre"
    done
    pe_i=1
    while [ "$pe_i" -le "$pe_count" ]; do
      if [ "$pe_kind" = mix ]; then
        if [ "$pe_i" -le $((pe_count / 2)) ]; then
          pe_word=Todo
        else
          pe_word=Task
        fi
      else
        pe_word=$pe_kind
      fi
      pe_line "$pe_word $pe_i: item $pe_i"
      pe_line 'loop: single -- reason: y'
      pe_line 'Files: a'
      pe_line 'Depends on: none'
      pe_i=$((pe_i + 1))
    done
  } > "$pe_file" || exit 2
}

TB_MISS='VIOLATION plan has 8 entries and no Token budget line'
plan_entries "$PLANS/tb-7-none.md" 7 Todo lf
plan_run tb-7-none "$PLANS/tb-7-none.md" 0 'OK plan-check: 7 entries'
plan_entries "$PLANS/tb-8-none.md" 8 Todo lf
plan_run_exact tb-8-none "$PLANS/tb-8-none.md" 1 "$TB_MISS"
plan_entries "$PLANS/tb-9-none.md" 9 Todo lf
plan_run_exact tb-9-none "$PLANS/tb-9-none.md" 1 'VIOLATION plan has 9 entries and no Token budget line'
plan_entries "$PLANS/tb-8-malformed.md" 8 Todo lf 'Token budget: todos=8 minimum-dispatches=30'
plan_run_exact tb-8-malformed "$PLANS/tb-8-malformed.md" 1 "$TB_MISS"
plan_entries "$PLANS/tb-8-nonnumeric.md" 8 Todo lf 'Token budget: todos=8 minimum-dispatches=30 tokens-per-dispatch=abc'
plan_run_exact tb-8-nonnumeric "$PLANS/tb-8-nonnumeric.md" 1 "$TB_MISS"
plan_entries "$PLANS/tb-8-negative.md" 8 Todo lf 'Token budget: todos=8 minimum-dispatches=30 tokens-per-dispatch=-5'
plan_run_exact tb-8-negative "$PLANS/tb-8-negative.md" 1 "$TB_MISS"
plan_entries "$PLANS/tb-8-trailing-field.md" 8 Todo lf 'Token budget: todos=8 minimum-dispatches=30 tokens-per-dispatch=unmeasured extra'
plan_run_exact tb-8-trailing-field "$PLANS/tb-8-trailing-field.md" 1 "$TB_MISS"
plan_entries "$PLANS/tb-8-indented.md" 8 Todo lf '  Token budget: todos=8 minimum-dispatches=30 tokens-per-dispatch=unmeasured'
plan_run_exact tb-8-indented "$PLANS/tb-8-indented.md" 1 "$TB_MISS"
plan_entries "$PLANS/tb-8-fenced.md" 8 Todo lf '```' 'Token budget: todos=8 minimum-dispatches=30 tokens-per-dispatch=unmeasured' '```'
plan_run_exact tb-8-fenced "$PLANS/tb-8-fenced.md" 1 "$TB_MISS"
plan_entries "$PLANS/tb-8-mixed-none.md" 8 mix lf
plan_run_exact tb-8-mixed-none "$PLANS/tb-8-mixed-none.md" 1 "$TB_MISS"
plan_entries "$PLANS/tb-8-unmeasured.md" 8 Todo lf 'Token budget: todos=8 minimum-dispatches=30 tokens-per-dispatch=unmeasured'
plan_run tb-8-unmeasured "$PLANS/tb-8-unmeasured.md" 0 'OK plan-check: 8 entries'
plan_entries "$PLANS/tb-8-integer.md" 8 Todo lf 'Token budget: todos=8 minimum-dispatches=30 tokens-per-dispatch=12000'
plan_run tb-8-integer "$PLANS/tb-8-integer.md" 0 'OK plan-check: 8 entries'
plan_entries "$PLANS/tb-8-crlf.md" 8 Todo crlf 'Token budget: todos=8 minimum-dispatches=30 tokens-per-dispatch=unmeasured'
plan_run tb-8-crlf "$PLANS/tb-8-crlf.md" 0 'OK plan-check: 8 entries'
plan_entries "$PLANS/tb-8-two-lines.md" 8 Todo lf 'Token budget: todos=8 minimum-dispatches=30 tokens-per-dispatch=unmeasured' 'Token budget: todos=8 minimum-dispatches=30 tokens-per-dispatch=12000'
plan_run tb-8-two-lines "$PLANS/tb-8-two-lines.md" 0 'OK plan-check: 8 entries'
plan_entries "$PLANS/tb-3-valid.md" 3 Todo lf
plan_run tb-3-valid "$PLANS/tb-3-valid.md" 0 'OK plan-check: 3 entries'

printf '%s cases, %s failed\n' "$cases" "$failed"
if [ "$failed" -eq 0 ]; then
  exit 0
fi
exit 1
