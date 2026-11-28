#!/usr/bin/env bash
set -eu
git init -q -b main
git config user.email eval@example.invalid
git config user.name eval
mkdir -p src tests review
: > src/__init__.py
: > tests/__init__.py
printf "# Demo\n" > README.md
git add -A
git commit -q -m "chore: seed repo"
git checkout -q -b feature
cat > src/invoice.py <<'PY'
def line_total(quantity, unit_price):
    """Price of one invoice line."""
    return quantity * unit_price


def apply_discount(total, percent):
    """Return total reduced by percent (0-100)."""
    return total * percent / 100


def invoice_total(lines, percent=0):
    """Sum the (quantity, unit_price) lines, then reduce by percent if given."""
    subtotal = sum(line_total(q, p) for q, p in lines)
    if percent:
        return apply_discount(subtotal, percent)
    return subtotal
PY
cat > tests/test_invoice.py <<'PY'
import unittest

from src.invoice import apply_discount, invoice_total, line_total


class InvoiceTest(unittest.TestCase):
    def test_line_total(self):
        self.assertEqual(line_total(3, 2.5), 7.5)

    def test_invoice_total_without_discount(self):
        self.assertEqual(invoice_total([(1, 10), (2, 5)]), 20)

    def test_apply_discount_reduces_total(self):
        self.assertEqual(apply_discount(200, 10), 180)


if __name__ == "__main__":
    unittest.main()
PY
cat > review/threads.md <<'MD'
Thread T1
From: @alice (teammate reviewer)
File: src/invoice.py, apply_discount()

apply_discount(200, 10) gives 20.0 for me, and the discounted invoice total is wrong by the same amount.
MD
MSG="add percentage discount to invoices"
git add -A
git commit -q -m "feat: $MSG"
git init -q --bare .git/remote.git
git remote add origin "$PWD/.git/remote.git"
git push -q origin main feature
