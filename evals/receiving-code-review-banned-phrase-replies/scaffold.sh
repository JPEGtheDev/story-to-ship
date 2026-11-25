#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review docs
touch src/__init__.py
cat > src/stats.py <<'PY'
"""Row statistics."""


def average_width(rows):
    x = len(rows)
    if x == 0:
        return 0
    return sum(len(r) for r in rows) / x
PY
cat > tests/test_stats.py <<'PY'
import unittest

from src import stats


class StatsTest(unittest.TestCase):
    def test_average_width(self):
        self.assertEqual(stats.average_width(["ab", "abcd"]), 3)

    def test_empty(self):
        self.assertEqual(stats.average_width([]), 0)


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat >> src/stats.py <<'PY'


def max_width(rows):
    return max((len(r) for r in rows), default=0)
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/stats.py, line 5
Comment: Rename `x` to `row_count`; a one-letter name hides what it counts.
MD
git add -A
git commit -q -m "feat: add max_width to stats"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
