#!/bin/sh
# Shared helpers for the running-a-sprint script tests. Each *.test.sh file sources this file,
# runs its cases with the assert helpers, and ends with test_summary.
# Fixtures live under one mktemp directory that the EXIT trap removes.
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
export LC_ALL=C.UTF-8 GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

TEST_PASS=0
TEST_FAIL=0
TEST_TMP=$(mktemp -d) || exit 2
trap 'rm -rf "$TEST_TMP"' EXIT

# pass_case <name>: record a passing assertion.
pass_case() {
  TEST_PASS=$((TEST_PASS + 1))
  printf 'ok   %s\n' "$1"
}

# fail_case <name> <reason>: record a failing assertion.
fail_case() {
  TEST_FAIL=$((TEST_FAIL + 1))
  printf 'FAIL %s: %s\n' "$1" "$2"
}

# assert_exit <name> <expected> <actual>: compare two exit codes.
assert_exit() {
  if [ "$2" -eq "$3" ]; then
    pass_case "$1"
  else
    fail_case "$1" "expected exit $2 got $3"
  fi
}

# assert_file_eq <name> <expected file> <actual file>: byte-for-byte match of two files.
assert_file_eq() {
  if cmp -s "$2" "$3"; then
    pass_case "$1"
  else
    fail_case "$1" "output differs"
    printf -- '--- expected\n'
    cat "$2"
    printf -- '--- actual\n'
    cat "$3"
  fi
}

# assert_empty <name> <file>: the file has no bytes.
assert_empty() {
  if [ ! -s "$2" ]; then
    pass_case "$1"
  else
    fail_case "$1" "expected no output, got:"
    cat "$2"
  fi
}

# assert_nonempty <name> <file>: the file has at least one byte.
assert_nonempty() {
  if [ -s "$2" ]; then
    pass_case "$1"
  else
    fail_case "$1" "expected a message, got none"
  fi
}

# assert_grep <name> <ERE pattern> <file>: the file matches the pattern, case-insensitive.
assert_grep() {
  if grep -qiE -e "$2" "$3"; then
    pass_case "$1"
  else
    fail_case "$1" "no line matches $2"
    cat "$3"
  fi
}

# git_c <dir> <git args...>: git with a fixed identity and no signing, run with -C (never cd).
git_c() {
  _gd=$1
  shift
  git -C "$_gd" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false "$@"
}

# make_repo <dir>: a repository on branch agent/s427-t1-tw with a base commit (main) and one
# feature commit on top. Sets FIX_BASE to the base sha and FIX_HEAD to the feature sha.
# shellcheck disable=SC2034
make_repo() {
  git init -q -b main "$1" || return 1
  printf '%s\n' 'base' > "$1/file.txt" || return 1
  git_c "$1" add -A || return 1
  git_c "$1" commit -q -m base || return 1
  FIX_BASE=$(git -C "$1" rev-parse HEAD) || return 1
  git_c "$1" checkout -q -b agent/s427-t1-tw || return 1
  printf '%s\n' 'feature' >> "$1/file.txt" || return 1
  git_c "$1" commit -q -a -m feature || return 1
  FIX_HEAD=$(git -C "$1" rev-parse HEAD) || return 1
}

# write_gh_stub <file>: a gh stand-in. It exits with STUB_EXIT when that is set,
# otherwise it prints the file named by STUB_JSON.
# The single-quoted lines are stub source text, so their $ must stay unexpanded.
# shellcheck disable=SC2016
write_gh_stub() {
  printf '%s\n' '#!/bin/sh' 'if [ -n "${STUB_EXIT:-}" ]; then exit "$STUB_EXIT"; fi' 'cat "$STUB_JSON"' > "$1" || return 1
  chmod +x "$1" || return 1
}

# write_pr_json <file> <state> <isDraft> <mergeable> <headRefOid> [rollup JSON] [body file]: a gh pr view
# document for PR 431. The rollup is raw JSON for statusCheckRollup and defaults to an empty array. The
# body is read byte for byte from the optional file (as a JSON string) and defaults to an empty body.
write_pr_json() {
  _body='""'
  if [ -n "${7:-}" ]; then
    _body=$(jq -Rs . < "$7") || return 1
  fi
  printf '{"number":431,"state":"%s","isDraft":%s,"mergeable":"%s","headRefOid":"%s","statusCheckRollup":%s,"body":%s}\n' \
    "$2" "$3" "$4" "$5" "${6:-[]}" "$_body" > "$1"
}

# test_summary: print the counts and exit 0 when no assertion failed, 1 otherwise.
test_summary() {
  printf '%s: %s passed, %s failed\n' "$(basename "$0")" "$TEST_PASS" "$TEST_FAIL"
  if [ "$TEST_FAIL" -eq 0 ]; then
    exit 0
  fi
  exit 1
}
