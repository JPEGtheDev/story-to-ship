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
cat > src/batch.py <<'PY'
def pages(items, size):
    """Split items into consecutive lists of at most size entries."""
    return [items[i:i + size] for i in range(0, len(items) - size, size)]


def flatten(pages_):
    """Join a list of pages back into one list."""
    return [x for page in pages_ for x in page]
PY
cat > tests/test_batch.py <<'PY'
import unittest

from src.batch import flatten, pages


class BatchTest(unittest.TestCase):
    def test_pages_keep_every_item(self):
        self.assertEqual(pages([1, 2, 3, 4], 2), [[1, 2], [3, 4]])

    def test_flatten(self):
        self.assertEqual(flatten([[1, 2], [3]]), [1, 2, 3])


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/batch.py, line 3

nit: this might drop the last item.
MD
git add -A
git commit -q -m "feat: add page splitting"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
