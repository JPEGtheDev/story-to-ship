import json, os, re, sys, unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import contracts

PROMPT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "judge_prompt.md")


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

    def test_judge_prompt_json_block_matches_verdict_fields(self):
        """Guards against the prompt the real judge reads drifting from the
        code contract: parses the single fenced json block out of
        judge_prompt.md and asserts its key set equals contracts.VERDICT_FIELDS."""
        with open(PROMPT_PATH, "r", encoding="ascii") as f:
            text = f.read()
        blocks = re.findall(r"```json\s*\n(.*?)```", text, re.DOTALL)
        self.assertEqual(
            len(blocks),
            1,
            f"expected exactly one fenced json block in judge_prompt.md, found {len(blocks)}",
        )
        parsed = json.loads(blocks[0])
        self.assertEqual(set(parsed.keys()), set(contracts.VERDICT_FIELDS))


if __name__ == "__main__":
    unittest.main()
