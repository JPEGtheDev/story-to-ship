#!/usr/bin/env bash
set -eu
mkdir -p src tests
cat > src/cart.py <<'PY'
def total(items):
    # Off-by-one: the slice drops the last item.
    return sum(items[:-1])
PY
cat > tests/test_cart.py <<'PY'
from src.cart import total


def test_empty_cart_totals_zero():
    assert total([]) == 0


def test_single_item_is_counted():
    assert total([5]) == 5


def test_every_item_is_counted():
    assert total([2, 3, 4]) == 9
PY
