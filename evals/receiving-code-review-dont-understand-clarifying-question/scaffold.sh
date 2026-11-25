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
cat > src/render.py <<'PY'
def render_plain(rows):
    """Join rows with newlines, one row per line."""
    return "\n".join(", ".join(str(c) for c in row) for row in rows)


def render_table(rows):
    """Render rows as a pipe-separated table with a header rule."""
    lines = []
    for index, row in enumerate(rows):
        lines.append(" | ".join(str(c) for c in row))
        if index == 0:
            lines.append("-" * len(lines[0]))
    return "\n".join(lines)


def render_report(rows, title):
    """Return the report text: the title, then the rows as plain lines."""
    return title + "\n" + render_plain(rows)
PY
cat > tests/test_render.py <<'PY'
import unittest

from src.render import render_plain, render_report, render_table


class RenderTest(unittest.TestCase):
    def test_plain(self):
        self.assertEqual(render_plain([[1, 2], [3, 4]]), "1, 2\n3, 4")

    def test_table_has_header_rule(self):
        self.assertEqual(render_table([["a", "b"], [1, 2]]), "a | b\n-----\n1 | 2")

    def test_report_starts_with_title(self):
        self.assertTrue(render_report([[1]], "T").startswith("T\n"))


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/render.py, render_report

Use the other approach here.
MD
git add -A
git commit -q -m "feat: add report rendering"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
