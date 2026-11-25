#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review docs
touch src/__init__.py
cat > src/validate.py <<'PY'
"""Input validation."""


def validate_age(age):
    return isinstance(age, int)
PY
cat > src/export.py <<'PY'
"""CSV export."""
from src.validate import validate_age


def export_rows(rows):
    lines = ["name,age"]
    for name, age in rows:
        if validate_age(age):
            lines.append("{},{}".format(name, age))
    return "\n".join(lines)
PY
cat > tests/test_export.py <<'PY'
import unittest

from src import export


class ExportTest(unittest.TestCase):
    def test_export(self):
        self.assertEqual(export.export_rows([("ann", 30)]), "name,age\nann,30")


if __name__ == "__main__":
    unittest.main()
PY
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat >> src/export.py <<'PY'


def export_header():
    return "name,age"
PY
cat > tests/test_validate.py <<'PY'
import unittest

from src import validate


class ValidateTest(unittest.TestCase):
    def test_accepts_adult(self):
        self.assertTrue(validate.validate_age(30))

    def test_rejects_negative(self):
        self.assertFalse(validate.validate_age(-5))


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
PR description: Add export_header to the CSV export. This PR only changes the export.

Thread T1
From: @alice (teammate reviewer)
File: src/validate.py, line 5
Comment: validate_age(-5) returns True, so the export writes negative ages.
MD
git add -A
git commit -q -m "feat: add export_header"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
