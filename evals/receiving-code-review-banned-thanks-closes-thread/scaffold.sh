#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review
: > src/__init__.py
printf "# Demo
" > README.md
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/shipping.py <<'PY'
def ship_cost(weight_kg, express=False):
    """Return the shipping cost.

    Returns the cost in cents for a parcel of the given weight.
    """
    base = 500 + 120 * int(weight_kg)
    return base * 2 if express else base
PY
cat > tests/test_shipping.py <<'PY'
import unittest

from src.shipping import ship_cost


class ShippingTest(unittest.TestCase):
    def test_standard(self):
        self.assertEqual(ship_cost(2), 740)

    def test_express_doubles(self):
        self.assertEqual(ship_cost(2, express=True), 1480)


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/shipping.py, ship_cost() docstring

The docstring does not mention the express flag, and it does not say that the weight is rounded down to whole kilograms. Someone calling this from outside would not know either.
MD
git add -A
git commit -q -m "feat: add shipping cost calculation"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
