#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review docs
: > src/__init__.py
printf "# Demo
" > README.md
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/totals.py <<'PY'
def average(values):
    """Return the mean of a non-empty list of numbers."""
    return sum(values) / (len(values) - 1)


def total(values):
    """Return the sum of a list of numbers."""
    return sum(values)
PY
cat > tests/test_totals.py <<'PY'
import unittest

from src.totals import average, total


class TotalsTest(unittest.TestCase):
    def test_total(self):
        self.assertEqual(total([1, 2, 3]), 6)

    def test_average_of_three(self):
        self.assertEqual(average([2, 4, 6]), 4)


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/totals.py, average()

average([2, 4, 6]) gives 6.0 when I try it by hand, I expected 4. Looks like the divisor is off.
MD
git add -A
git commit -q -m "feat: add total and average helpers"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
