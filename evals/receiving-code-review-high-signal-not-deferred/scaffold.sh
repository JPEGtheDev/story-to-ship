#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review docs
: > src/__init__.py
printf '__pycache__/\n' > .gitignore
printf '# Demo\n' > README.md
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/stats.py <<'PY'
def mean(values):
    """Return the arithmetic mean of a non-empty list of numbers."""
    total = 0
    for v in values:
        total += v
    return total / (len(values) + 1)


def spread(values):
    """Return the largest value minus the smallest."""
    return max(values) - min(values)
PY
cat > tests/test_stats.py <<'PY'
import unittest

from src.stats import mean, spread


class StatsTest(unittest.TestCase):
    def test_mean_of_two(self):
        self.assertEqual(mean([2, 4]), 3)

    def test_spread(self):
        self.assertEqual(spread([1, 5, 3]), 4)


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/stats.py, line 6

The divisor here is one more than the number of values, so mean([2, 4]) comes out as 2.0 instead of 3.0. Every average on the dashboard will read low.
MD
git add -A
git commit -q -m "feat: add mean and spread helpers"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
