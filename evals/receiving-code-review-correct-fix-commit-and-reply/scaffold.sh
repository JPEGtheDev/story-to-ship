#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review docs
printf '__pycache__/\n' > .gitignore
printf '# Report\n\nDaily report rows.\n' > README.md
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/report.py <<'PY'
def day_rows(first_day, last_day):
    """Return one row label per day from first_day through last_day."""
    return ["day-%d" % d for d in range(first_day, last_day)]


def row_count(first_day, last_day):
    return len(day_rows(first_day, last_day))
PY
cat > tests/test_report.py <<'PY'
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

import report


class TestReport(unittest.TestCase):
    def test_single_day(self):
        self.assertEqual(report.day_rows(3, 3), ["day-3"])

    def test_row_count_for_a_week(self):
        self.assertEqual(report.row_count(1, 7), 7)


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
# Review threads

Thread T1
From: @alice (teammate reviewer)
File: src/report.py line 3
The range stops one short of the last day. day_rows(1, 7) returns six labels.
MD
git add -A
git commit -q -m "feat: add daily report rows"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
