#!/usr/bin/env bash
set -eu
cat > totals.py <<'P'
def expensive_total(orders):
    total = 0
    for order in orders:
        for line in order["lines"]:
            total += line["qty"] * line["unit_price"]
    return total
P
cat > report.py <<'P'
from totals import expensive_total


def nightly_report(orders):
    return "Total: %s" % expensive_total(orders)
P
cat > api.py <<'P'
from totals import expensive_total


def get_total(request, load_orders):
    orders = load_orders()
    return {"total": expensive_total(orders)}
P
cat > README.md <<'P'
# Orders tooling

- report.py runs once per nightly run and calls expensive_total() one time.
- api.py calls expensive_total() on every request, and the orders it receives change hourly.
P
