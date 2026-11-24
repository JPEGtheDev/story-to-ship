#!/usr/bin/env bash
set -eu
mkdir -p src tests
# The eval sandbox is a git repository the harness creates; ignore it all so the plugin write guards, which exempt ignored paths, do not block a case that measures the testing skill.
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
