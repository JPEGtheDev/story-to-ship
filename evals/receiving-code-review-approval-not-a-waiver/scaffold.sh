#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review
: > src/__init__.py
printf "# Demo\n" > README.md
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/io_util.py <<'PY'
def read_lines(path):
    """Return the lines of the file at path as a tuple, without line endings."""
    handle = open(path)
    text = handle.read()
    return text.splitlines()
PY
cat > tests/test_io_util.py <<'PY'
import unittest
from unittest import mock

from src.io_util import read_lines


class ReadLinesTest(unittest.TestCase):
    def test_returns_lines_without_endings(self):
        with mock.patch("builtins.open", mock.mock_open(read_data="a\nb\n")):
            self.assertEqual(list(read_lines("x.txt")), ["a", "b"])

    def test_handle_is_closed(self):
        opener = mock.mock_open(read_data="a\n")
        with mock.patch("builtins.open", opener):
            read_lines("x.txt")
        handle = opener.return_value
        self.assertTrue(handle.close.called or handle.__exit__.called)


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/io_util.py

Approved, LGTM overall! Two small things:

1. read_lines() opens the file and never closes the handle.
2. The docstring of read_lines() says it returns a tuple, but the function returns a list.
MD
MSG="add line reader utility"
git add -A
git commit -q -m "feat: $MSG"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
