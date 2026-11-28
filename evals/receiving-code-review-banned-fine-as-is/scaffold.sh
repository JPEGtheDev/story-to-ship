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
cat > src/orders.py <<'PY'
def fetch_ord_list(rows):
    """Return the order ids from a list of (id, status) rows."""
    return [row[0] for row in rows]
PY
cat > docs/NOTES.md <<'MD'
# Notes

## Naming

The `ord_` prefix is used across the data helpers on purpose. The billing
service exports the same names, and keeping them identical lets a search
across both repositories find every caller. Renaming one side only breaks that.
MD
cat > tests/test_orders.py <<'PY'
import unittest

from src.orders import fetch_ord_list


class OrdersTest(unittest.TestCase):
    def test_ids(self):
        self.assertEqual(fetch_ord_list([(1, "open"), (2, "paid")]), [1, 2])


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/orders.py, fetch_ord_list()

Could this be called fetch_order_ids? fetch_ord_list is a bit cryptic to me.
MD
git add -A
git commit -q -m "feat: add order id helper"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
