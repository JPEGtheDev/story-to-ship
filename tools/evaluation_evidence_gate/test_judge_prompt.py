import json, os, re, sys, unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import contracts

PROMPT_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "judge_prompt.md")


def _read_prompt():
    with open(PROMPT_PATH, "r", encoding="ascii") as f:
        return f.read()


def _extract_json_blocks(text):
    return re.findall(r"```json\s*\n(.*?)```", text, re.DOTALL)


class JudgePromptTest(unittest.TestCase):
    """Content-level checks on the pinned judge prompt (judge_prompt.md).

    These assert on the actual meaning of the prompt text, not on bare
    section-header presence, so a prompt that has the right headings but
    hollow content still fails.
    """

    @classmethod
    def setUpClass(cls):
        cls.text = _read_prompt()

    def test_model_line_pins_sonnet_or_higher(self):
        first_line = self.text.splitlines()[0]
        self.assertTrue(
            first_line.startswith("model:"),
            f"first line must be a 'model:' line, got: {first_line!r}",
        )
        self.assertRegex(
            first_line,
            r"claude-(sonnet|opus)",
            "model: line must pin a Sonnet-or-higher model id",
        )

    def test_verdict_class_covers_all_three_claim_kinds(self):
        lower = self.text.lower()
        self.assertIn("coverage", lower)
        self.assertRegex(
            lower,
            r"closure|completion",
            "verdict class must mention closure/completion claims",
        )
        self.assertIn("causal", lower)

    def test_evidence_requirement_states_inline_quoted_primary_adjacent(self):
        lower = self.text.lower()
        self.assertIn("inline", lower)
        self.assertIn("quoted", lower)
        self.assertIn("primary", lower)
        self.assertIn("adjacent", lower)

    def test_counterfeit_rule_and_fewshot_present(self):
        lower = self.text.lower()
        self.assertRegex(
            lower,
            r"counterfeit",
            "must state a counterfeit-evidence rule",
        )
        self.assertIn('"backed": false', self.text)
        # The counterfeit few-shot must pair evidence-shaped prose (a claim
        # about passing tests) with a false backing verdict in the same
        # example block.
        self.assertRegex(
            self.text,
            r"(?s)tests? pass.{0,400}?\"backed\":\s*false|"
            r"\"backed\":\s*false.{0,400}?tests? pass",
            "counterfeit few-shot must co-occur an evidence-shaped claim with backed:false",
        )

    def test_genuinely_backed_fewshot_present(self):
        self.assertIn('"backed": true', self.text)
        self.assertRegex(
            self.text,
            r"(?s)\"backed\":\s*true.{0,400}?(unittest|Ran \d+ tests?)|"
            r"(unittest|Ran \d+ tests?).{0,400}?\"backed\":\s*true",
            "backed:true example must quote a real command/tool/file output",
        )

    def test_exactly_one_fenced_json_block_valid_and_matches_schema(self):
        blocks = _extract_json_blocks(self.text)
        self.assertEqual(
            len(blocks),
            1,
            f"expected exactly one fenced json block, found {len(blocks)}",
        )
        parsed = json.loads(blocks[0])
        self.assertEqual(set(parsed.keys()), set(contracts.VERDICT_FIELDS))


if __name__ == "__main__":
    unittest.main()
