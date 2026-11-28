#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review docs
printf '__pycache__/\n' > .gitignore
printf '# Cart\n\nSmall cart helpers.\n' > README.md
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/cart.py <<'PY'
def total(prices, tax_rate):
    subtotal = 0.0
    for p in prices:
        subtotal += float(p)
    return subtotal * (1 + tax_rate)


def item_count(prices):
    return len(prices)
PY
cat > tests/test_cart.py <<'PY'
import os
import sys
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

import cart


class TestCart(unittest.TestCase):
    def test_total_with_tax(self):
        self.assertAlmostEqual(cart.total([10, 20], 0.1), 33.0)

    def test_item_count(self):
        self.assertEqual(cart.item_count([1, 2, 3]), 3)


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
# Review threads

Thread T1
From: @alice (teammate reviewer)
File: src/cart.py line 4
total() accumulates prices as float. Prices are money amounts and the sum can drift by a cent. Use Decimal.

Thread T2
From: @alice (teammate reviewer)
File: tests/test_cart.py
There is no test for an empty cart.

Thread T3
From: @alice (teammate reviewer)
File: src/cart.py line 7
Two blank lines between top-level functions would match the rest of our modules.
MD
git add -A
git commit -q -m "feat: add cart total and item count"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
