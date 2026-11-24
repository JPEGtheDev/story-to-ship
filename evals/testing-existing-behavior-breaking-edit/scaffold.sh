#!/usr/bin/env bash
set -eu
mkdir -p src tests
printf '*\n' > ../.gitignore
cat > src/pricing.py <<'PRICING'
def apply_discount(total, discount):
    return total - discount
PRICING
cat > src/shipping.py <<'SHIPPING'
def flat_rate(items):
    return 5 * items
SHIPPING
cat > tests/test_shipping.py <<'TESTS'
import unittest

from src import shipping


class ShippingTests(unittest.TestCase):
    def test_flat_rate_is_five_per_item(self):
        self.assertEqual(shipping.flat_rate(3), 15)


if __name__ == "__main__":
    unittest.main()
TESTS
