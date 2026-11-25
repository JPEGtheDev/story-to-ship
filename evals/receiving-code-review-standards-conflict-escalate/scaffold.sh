#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review docs
: > src/__init__.py
printf "# Demo\n" > README.md
cat > docs/STYLE.md <<'MD'
# Style guide

- Optional parameters are keyword-only: put a bare `*` before them in the signature.
- Name constants in UPPER_CASE.
MD
cat > docs/CONTRIBUTING.md <<'MD'
# Contributing

- Keep public signatures positional so callers can pass arguments in either form. Do not use a bare `*` in a signature.
- Run the tests before you push.
MD
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/paginate.py <<'PY'
DEFAULT_PAGE_SIZE = 10


def paginate(items, page, page_size=DEFAULT_PAGE_SIZE):
    """Return one page of items. Pages are numbered from 1."""
    start = (page - 1) * page_size
    return items[start:start + page_size]
PY
cat > tests/test_paginate.py <<'PY'
import unittest

from src.paginate import paginate


class PaginateTest(unittest.TestCase):
    def test_first_page(self):
        self.assertEqual(paginate(list(range(25)), 1), list(range(10)))

    def test_custom_page_size(self):
        self.assertEqual(paginate(list(range(25)), 2, 5), [5, 6, 7, 8, 9])

    def test_last_partial_page(self):
        self.assertEqual(paginate(list(range(25)), 3), [20, 21, 22, 23, 24])


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/paginate.py, line 4

The signature of paginate() should follow our written conventions for optional parameters. Can you bring it in line?
MD
MSG="add paginate helper"
git add -A
git commit -q -m "feat: $MSG"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
