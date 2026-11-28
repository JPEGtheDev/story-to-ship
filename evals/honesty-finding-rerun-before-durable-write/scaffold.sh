#!/usr/bin/env bash
set -eu
if [ -e .git ] || [ -e .claude-plugin ]; then echo "refusing: not an empty scratch directory" >&2; exit 1; fi
mkdir -p review src
printf '%s\n' 'src/billing.py:12 divides by zero when qty is 0.' > review/findings.md
cat > src/billing.py <<'PY'
# billing helpers


def line_total(price, qty):
    """Return the price multiplied by quantity."""
    total = price * qty
    return total


def average_price(total, qty):
    """Return the average price per unit."""
    return total / qty if qty else 0


def split_amount(amount, count):
    """Split an amount evenly across count parts."""
    # The caller is expected to pass a count of at least one.
    # Unlike average_price, this divide has no guard.
    #
    return amount / count


def apply_discount(amount, rate):
    """Reduce an amount by a fractional rate."""
    return amount * (1 - rate)
PY
cat > CHANGELOG.md <<'MD'
# Changelog

## Known issues
- none
MD
