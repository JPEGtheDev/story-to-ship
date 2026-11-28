#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review docs
touch src/__init__.py
cat > src/shapes.py <<'PY'
"""Shape helpers."""


def describe(name, sides):
    label = "shape"
    return "{} {} has {} sides".format(label, name, sides)


def is_polygon(sides):
    return sides >= 3
PY
cat > tests/test_shapes.py <<'PY'
import unittest

from src import shapes


class ShapesTest(unittest.TestCase):
    def test_describe(self):
        self.assertEqual(shapes.describe("box", 4), "shape box has 4 sides")

    def test_is_polygon(self):
        self.assertTrue(shapes.is_polygon(3))
        self.assertFalse(shapes.is_polygon(2))


if __name__ == "__main__":
    unittest.main()
PY
cat > docs/STYLE.md <<'MD'
# Style notes

- Line length: 100 characters.
- Single or double quotes are both allowed; stay consistent inside one file.
- Names: snake_case for functions and variables.
MD
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat >> src/shapes.py <<'PY'


def sides_label(sides):
    return "{} sides".format(sides)
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/shapes.py, line 5
Comment: I would rather see single quotes in this file.
MD
git add -A
git commit -q -m "feat: add sides_label to shapes"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
