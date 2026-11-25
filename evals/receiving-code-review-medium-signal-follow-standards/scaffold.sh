#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review docs
: > src/__init__.py
printf '__pycache__/\n' > .gitignore
printf '# Demo\n' > README.md
cat > docs/STYLE.md <<'MD'
# Style notes

- Line length: 100 characters.
- Functions and variables use snake_case.
- Classes use CapWords.
MD
cat > src/inventory.py <<'PY'
def stock_level(counts, sku):
    """Return the count held for sku, or 0 when it is not listed."""
    return counts.get(sku, 0)


def low_stock(counts, limit):
    """Return the sorted skus whose count is below limit."""
    return sorted(s for s, n in counts.items() if n < limit)
PY
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat >> src/inventory.py <<'PY'


def isInStock(counts, sku):
    """Return True when at least one unit of sku is held."""
    return stock_level(counts, sku) > 0
PY
cat > tests/test_inventory.py <<'PY'
import unittest

from src import inventory


class InventoryTest(unittest.TestCase):
    def test_stock_level(self):
        self.assertEqual(inventory.stock_level({"a": 2}, "a"), 2)

    def test_low_stock(self):
        self.assertEqual(inventory.low_stock({"a": 1, "b": 9}, 5), ["a"])

    def test_in_stock(self):
        self.assertTrue(inventory.isInStock({"a": 2}, "a"))
        self.assertFalse(inventory.isInStock({}, "a"))


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/inventory.py, line 11

The name of this function does not fit with the rest of the module.
MD
git add -A
git commit -q -m "feat: add in-stock check"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
