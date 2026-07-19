import os, sys, unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import contracts


class SchemaContractTest(unittest.TestCase):
    """Locks the JSONL field-name tuples in contracts.py to their exact,
    verbatim values. A rename, reorder, or drop of any field must fail
    this test, since contracts.py is the single source of truth consumed
    by the audit runner (and, in Task 2, cross-checked against
    judge_prompt.md)."""

    def test_turn_fields(self):
        self.assertEqual(
            contracts.TURN_FIELDS,
            ("turn_id", "session_id", "timestamp", "turn_type", "final_text", "source_uuid"),
        )

    def test_verdict_fields(self):
        self.assertEqual(
            contracts.VERDICT_FIELDS,
            ("turn_id", "verdict_present", "backed"),
        )

    def test_label_fields(self):
        self.assertEqual(
            contracts.LABEL_FIELDS,
            ("turn_id", "is_unbacked_verdict", "turn_type"),
        )

    def test_turn_types(self):
        self.assertEqual(
            contracts.TURN_TYPES,
            ("completion_claim", "hand_off", "question", "other"),
        )


if __name__ == "__main__":
    unittest.main()
