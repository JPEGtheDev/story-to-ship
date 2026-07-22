import json, os, sys, tempfile, unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import contracts
import audit_extract

FIXTURE_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "fixtures", "mini_transcript.jsonl"
)


def load_fixture_lines():
    with open(FIXTURE_PATH, "r", encoding="ascii") as f:
        return [json.loads(line) for line in f if line.strip()]


def write_temp_transcript(raw_lines):
    """Write raw_lines (already-serialized strings, one per JSONL line) to a
    temp file and return its path. Caller must remove the file."""
    with tempfile.NamedTemporaryFile(
        mode="w", suffix=".jsonl", delete=False, encoding="ascii"
    ) as f:
        f.write("\n".join(raw_lines) + "\n")
        return f.name


class IterMainThreadTest(unittest.TestCase):
    """(c) an isSidechain: true line is excluded entirely."""

    def test_excludes_sidechain_lines(self):
        lines = load_fixture_lines()
        main_thread = list(audit_extract.iter_main_thread(lines))
        self.assertTrue(all(not line.get("isSidechain") for line in main_thread))
        self.assertNotIn("u-side1", [line.get("uuid") for line in main_thread])

    def test_keeps_non_sidechain_lines(self):
        lines = load_fixture_lines()
        main_thread = list(audit_extract.iter_main_thread(lines))
        # 12 lines in fixture, 1 is a sidechain line -> 11 remain.
        self.assertEqual(len(main_thread), 11)

    def test_line_omitting_isSidechain_is_treated_as_main_thread(self):
        line = {
            "type": "user",
            "message": {"role": "user", "content": "start"},
            "uuid": "d-no-field",
        }
        self.assertIn(line, list(audit_extract.iter_main_thread([line])))

    def test_explicit_sidechain_true_is_still_excluded(self):
        line = {
            "type": "user",
            "isSidechain": True,
            "message": {"role": "user", "content": "start"},
            "uuid": "d-side",
        }
        self.assertNotIn(line, list(audit_extract.iter_main_thread([line])))


class IsTurnDelimiterTest(unittest.TestCase):
    def test_string_content_is_delimiter(self):
        line = {"type": "user", "message": {"role": "user", "content": "Please continue."}}
        self.assertTrue(audit_extract.is_turn_delimiter(line))

    def test_array_with_text_block_is_delimiter(self):
        line = {
            "type": "user",
            "message": {"role": "user", "content": [{"type": "text", "text": "hi"}]},
        }
        self.assertTrue(audit_extract.is_turn_delimiter(line))

    def test_array_of_only_tool_result_is_not_delimiter(self):
        """(a) tool_result user lines are NOT treated as delimiters."""
        line = {
            "type": "user",
            "message": {
                "role": "user",
                "content": [{"type": "tool_result", "content": "output"}],
            },
        }
        self.assertFalse(audit_extract.is_turn_delimiter(line))

    def test_assistant_line_is_not_delimiter(self):
        line = {
            "type": "assistant",
            "message": {"role": "assistant", "content": [{"type": "text", "text": "hi"}]},
        }
        self.assertFalse(audit_extract.is_turn_delimiter(line))

    def test_null_message_does_not_crash(self):
        """(A3) message: null must not raise AttributeError."""
        line = {"type": "user", "message": None}
        self.assertFalse(audit_extract.is_turn_delimiter(line))


class SplitTurnsTest(unittest.TestCase):
    def test_tool_result_does_not_split_a_turn(self):
        """(a) a turn spans across a tool_result line correctly."""
        lines = load_fixture_lines()
        main_thread = list(audit_extract.iter_main_thread(lines))
        turns = audit_extract.split_turns(main_thread)
        # Turn 1 (index 0) must contain the tool_use line, the tool_result
        # line, and the final assistant line -- 3 lines total.
        first_turn = turns[0]
        self.assertEqual(len(first_turn), 3)
        self.assertEqual(first_turn[1]["uuid"], "u-tr1")

    def test_lines_before_first_delimiter_are_ignored(self):
        main_thread = [
            {
                "type": "assistant",
                "isSidechain": False,
                "message": {"role": "assistant", "content": [{"type": "text", "text": "orphan"}]},
                "uuid": "orphan-1",
            },
            {
                "type": "user",
                "isSidechain": False,
                "message": {"role": "user", "content": "start"},
                "uuid": "d-1",
            },
            {
                "type": "assistant",
                "isSidechain": False,
                "message": {"role": "assistant", "content": [{"type": "text", "text": "hi"}]},
                "uuid": "a-1",
            },
        ]
        turns = audit_extract.split_turns(main_thread)
        self.assertEqual(len(turns), 1)
        self.assertEqual(turns[0][0]["uuid"], "a-1")

    def test_five_turns_split_from_fixture(self):
        lines = load_fixture_lines()
        main_thread = list(audit_extract.iter_main_thread(lines))
        turns = audit_extract.split_turns(main_thread)
        self.assertEqual(len(turns), 5)


class FinalTextTest(unittest.TestCase):
    def test_excludes_thinking_and_concatenates_text_around_tool_use(self):
        """(b) thinking excluded. (d) multiple text blocks within one
        assistant message, with a tool_use block between them, are
        concatenated in order joined by '\\n\\n'."""
        turn_lines = [
            {
                "type": "assistant",
                "message": {
                    "role": "assistant",
                    "content": [
                        {"type": "thinking", "text": "internal reasoning about the fix"},
                        {"type": "text", "text": "First part of the fix."},
                        {"type": "tool_use", "name": "Read", "input": {"file": "x.py"}},
                        {"type": "text", "text": "Issue resolved and covered by tests."},
                    ],
                },
                "uuid": "u-a2",
            }
        ]
        text = audit_extract.final_text(turn_lines)
        self.assertEqual(text, "First part of the fix.\n\nIssue resolved and covered by tests.")

    def test_uses_last_text_bearing_assistant_message(self):
        turn_lines = [
            {
                "type": "assistant",
                "message": {
                    "role": "assistant",
                    "content": [{"type": "tool_use", "name": "Bash", "input": {}}],
                },
                "uuid": "no-text",
            },
            {
                "type": "assistant",
                "message": {
                    "role": "assistant",
                    "content": [{"type": "text", "text": "second"}],
                },
                "uuid": "has-text-1",
            },
            {
                "type": "assistant",
                "message": {
                    "role": "assistant",
                    "content": [{"type": "text", "text": "last"}],
                },
                "uuid": "has-text-2",
            },
        ]
        self.assertEqual(audit_extract.final_text(turn_lines), "last")

    def test_no_text_bearing_assistant_message_returns_none(self):
        """(e) a turn with zero assistant messages does not crash."""
        turn_lines = [
            {
                "type": "user",
                "message": {"role": "user", "content": [{"type": "tool_result", "content": "x"}]},
            }
        ]
        self.assertIsNone(audit_extract.final_text(turn_lines))

    def test_empty_turn_returns_none(self):
        self.assertIsNone(audit_extract.final_text([]))

    def test_text_block_missing_text_key_does_not_crash(self):
        """(A1) a text-type block with no "text" key must not raise KeyError;
        it contributes "" to the joined text."""
        turn_lines = [
            {
                "type": "assistant",
                "message": {"role": "assistant", "content": [{"type": "text"}]},
                "uuid": "u-missing-text",
            }
        ]
        text = audit_extract.final_text(turn_lines)
        self.assertEqual(text, "")

    def test_null_message_does_not_crash(self):
        """(A3) an assistant line with message: null must not raise
        AttributeError and must simply be treated as text-less."""
        turn_lines = [
            {"type": "assistant", "message": None, "uuid": "u-null-msg"},
            {
                "type": "assistant",
                "message": {"role": "assistant", "content": [{"type": "text", "text": "ok"}]},
                "uuid": "u-a2",
            },
        ]
        self.assertEqual(audit_extract.final_text(turn_lines), "ok")


class ClassifyTurnTypeTest(unittest.TestCase):
    """(f) each of the 4 turn_types is produced by at least one crafted turn."""

    def test_question(self):
        self.assertEqual(
            audit_extract.classify_turn_type("Should I proceed with the deployment now?"),
            "question",
        )

    def test_hand_off(self):
        self.assertEqual(
            audit_extract.classify_turn_type(
                "I've made the changes. Handing off to you for review."
            ),
            "hand_off",
        )

    def test_completion_claim(self):
        self.assertEqual(
            audit_extract.classify_turn_type(
                "First part of the fix.\n\nIssue resolved and covered by tests."
            ),
            "completion_claim",
        )

    def test_other(self):
        self.assertEqual(
            audit_extract.classify_turn_type("I looked at the logs and nothing stood out."),
            "other",
        )

    def test_question_precedence_over_completion_claim(self):
        # Last non-empty line ends with "?" -> question wins even though
        # "done" appears earlier in the text.
        self.assertEqual(
            audit_extract.classify_turn_type("The fix is done.\n\nShall I proceed?"),
            "question",
        )

    def test_incomplete_is_not_a_completion_claim(self):
        """(C) "incomplete" must not substring-match the "complete" cue --
        that is the opposite meaning."""
        self.assertEqual(
            audit_extract.classify_turn_type("The fix is incomplete."),
            "other",
        )

    def test_unresolved_is_not_a_completion_claim(self):
        """(C) "unresolved" must not substring-match the "resolved" cue."""
        self.assertEqual(
            audit_extract.classify_turn_type("This is unresolved."),
            "other",
        )

    def test_genuine_fixed_is_still_a_completion_claim(self):
        """(C) word-boundary matching must not break the real positive case."""
        self.assertEqual(
            audit_extract.classify_turn_type("The bug is fixed."),
            "completion_claim",
        )


class ExtractTurnsTest(unittest.TestCase):
    def setUp(self):
        self.turns = list(audit_extract.extract_turns(FIXTURE_PATH))

    def test_turn_count_skips_the_empty_turn(self):
        """(e) a turn with zero assistant messages is skipped, not emitted."""
        self.assertEqual(len(self.turns), 4)

    def test_keys_match_turn_fields_exactly(self):
        """(g) emitted dict keys equal exactly set(contracts.TURN_FIELDS)."""
        for turn in self.turns:
            self.assertEqual(set(turn.keys()), set(contracts.TURN_FIELDS))

    def test_first_turn_fields(self):
        turn = self.turns[0]
        self.assertEqual(
            turn["final_text"],
            "First part of the fix.\n\nIssue resolved and covered by tests.",
        )
        self.assertEqual(turn["turn_type"], "completion_claim")
        self.assertEqual(turn["source_uuid"], "u-a2")
        self.assertEqual(turn["session_id"], "sess-1")
        self.assertEqual(turn["timestamp"], "2026-07-19T10:00:10Z")

    def test_second_turn_is_a_question_and_excludes_sidechain_text(self):
        turn = self.turns[1]
        self.assertEqual(turn["final_text"], "Should I proceed with the deployment now?")
        self.assertEqual(turn["turn_type"], "question")
        self.assertEqual(turn["source_uuid"], "u-a3")

    def test_third_turn_is_hand_off(self):
        turn = self.turns[2]
        self.assertEqual(
            turn["final_text"], "I've made the changes. Handing off to you for review."
        )
        self.assertEqual(turn["turn_type"], "hand_off")
        self.assertEqual(turn["source_uuid"], "u-a4")

    def test_fourth_turn_is_other(self):
        turn = self.turns[3]
        self.assertEqual(turn["final_text"], "I looked at the logs and nothing stood out.")
        self.assertEqual(turn["turn_type"], "other")
        self.assertEqual(turn["source_uuid"], "u-a5")

    def test_all_four_turn_types_represented(self):
        self.assertEqual(
            {turn["turn_type"] for turn in self.turns}, set(contracts.TURN_TYPES)
        )

    def test_turn_id_is_session_namespaced_and_unique(self):
        """turn_id must be globally unique across files: it is built from the
        turn's own session_id, not a bare per-file integer, so turn 0 of one
        session transcript cannot collide with turn 0 of another."""
        for turn in self.turns:
            self.assertTrue(
                turn["turn_id"].startswith(f"{turn['session_id']}#"),
                f"turn_id {turn['turn_id']!r} does not start with "
                f"'{turn['session_id']}#'",
            )
        turn_ids = [turn["turn_id"] for turn in self.turns]
        self.assertEqual(len(turn_ids), len(set(turn_ids)))
        self.assertEqual(
            turn_ids, ["sess-1#0", "sess-1#1", "sess-1#2", "sess-1#3"]
        )


class MalformedTranscriptReadingTest(unittest.TestCase):
    """(A2) the transcript reader must skip bad lines, never abort the file."""

    def _extract(self, raw_lines):
        path = write_temp_transcript(raw_lines)
        try:
            return list(audit_extract.extract_turns(path))
        finally:
            os.remove(path)

    def test_corrupt_jsonl_line_is_skipped_surrounding_turns_still_extract(self):
        raw_lines = [
            json.dumps(
                {
                    "type": "user",
                    "isSidechain": False,
                    "message": {"role": "user", "content": "start"},
                    "uuid": "d-1",
                    "sessionId": "sess-x",
                    "timestamp": "t0",
                }
            ),
            json.dumps(
                {
                    "type": "assistant",
                    "isSidechain": False,
                    "message": {
                        "role": "assistant",
                        "content": [{"type": "text", "text": "ok before corrupt"}],
                    },
                    "uuid": "a-1",
                    "sessionId": "sess-x",
                    "timestamp": "t1",
                }
            ),
            # Truncated / undecodable line -- must be skipped, not abort the read.
            '{"type": "user", "isSidechain": false, "message": {"role": "user", "content": "next"',
            json.dumps(
                {
                    "type": "user",
                    "isSidechain": False,
                    "message": {"role": "user", "content": "next"},
                    "uuid": "d-2",
                    "sessionId": "sess-x",
                    "timestamp": "t2",
                }
            ),
            json.dumps(
                {
                    "type": "assistant",
                    "isSidechain": False,
                    "message": {
                        "role": "assistant",
                        "content": [{"type": "text", "text": "ok after corrupt"}],
                    },
                    "uuid": "a-2",
                    "sessionId": "sess-x",
                    "timestamp": "t3",
                }
            ),
        ]
        turns = self._extract(raw_lines)
        self.assertEqual(len(turns), 2)
        self.assertEqual(turns[0]["final_text"], "ok before corrupt")
        self.assertEqual(turns[1]["final_text"], "ok after corrupt")

    def test_non_dict_json_line_is_skipped(self):
        raw_lines = [
            json.dumps(
                {
                    "type": "user",
                    "isSidechain": False,
                    "message": {"role": "user", "content": "start"},
                    "uuid": "d-1",
                    "sessionId": "sess-y",
                    "timestamp": "t0",
                }
            ),
            json.dumps([1, 2, 3]),  # valid JSON, not a dict -- must be skipped
            json.dumps(
                {
                    "type": "assistant",
                    "isSidechain": False,
                    "message": {
                        "role": "assistant",
                        "content": [{"type": "text", "text": "fine"}],
                    },
                    "uuid": "a-1",
                    "sessionId": "sess-y",
                    "timestamp": "t1",
                }
            ),
        ]
        turns = self._extract(raw_lines)
        self.assertEqual(len(turns), 1)
        self.assertEqual(turns[0]["final_text"], "fine")

    def test_null_message_line_does_not_crash_extraction(self):
        raw_lines = [
            json.dumps(
                {
                    "type": "user",
                    "isSidechain": False,
                    "message": {"role": "user", "content": "start"},
                    "uuid": "d-1",
                    "sessionId": "sess-z",
                    "timestamp": "t0",
                }
            ),
            json.dumps(
                {
                    "type": "assistant",
                    "isSidechain": False,
                    "message": None,
                    "uuid": "a-null",
                    "sessionId": "sess-z",
                    "timestamp": "t1",
                }
            ),
            json.dumps(
                {
                    "type": "assistant",
                    "isSidechain": False,
                    "message": {
                        "role": "assistant",
                        "content": [{"type": "text", "text": "final answer"}],
                    },
                    "uuid": "a-2",
                    "sessionId": "sess-z",
                    "timestamp": "t2",
                }
            ),
        ]
        turns = self._extract(raw_lines)
        self.assertEqual(len(turns), 1)
        self.assertEqual(turns[0]["final_text"], "final answer")


class Utf8TranscriptReadingTest(unittest.TestCase):
    """Real transcripts are UTF-8 (e.g. an em-dash U+2014 in assistant
    prose). The reader must not crash on non-ASCII bytes, and the
    non-ASCII character must round-trip faithfully into final_text."""

    def test_non_ascii_assistant_text_round_trips_without_crashing(self):
        raw_lines = [
            json.dumps(
                {
                    "type": "user",
                    "isSidechain": False,
                    "message": {"role": "user", "content": "start"},
                    "uuid": "d-1",
                    "sessionId": "sess-utf8",
                    "timestamp": "t0",
                },
                ensure_ascii=False,
            ),
            json.dumps(
                {
                    "type": "assistant",
                    "isSidechain": False,
                    "message": {
                        "role": "assistant",
                        "content": [{"type": "text", "text": "Fix applied — done"}],
                    },
                    "uuid": "a-1",
                    "sessionId": "sess-utf8",
                    "timestamp": "t1",
                },
                ensure_ascii=False,
            ),
        ]
        # Unlike write_temp_transcript above, this fixture MUST be written as
        # utf-8: it contains a raw (non-escaped) non-ASCII character, which
        # cannot be encoded as ascii.
        with tempfile.NamedTemporaryFile(
            mode="w", suffix=".jsonl", delete=False, encoding="utf-8"
        ) as f:
            f.write("\n".join(raw_lines) + "\n")
            path = f.name
        try:
            turns = list(audit_extract.extract_turns(path))
        finally:
            os.remove(path)
        self.assertEqual(len(turns), 1)
        self.assertIn("—", turns[0]["final_text"])


class LastTextMessageTest(unittest.TestCase):
    """(B) the shared scan that final_text and extract_turns both rely on."""

    def test_returns_line_and_text_from_same_message(self):
        turn_lines = [
            {
                "type": "assistant",
                "message": {
                    "role": "assistant",
                    "content": [{"type": "text", "text": "first"}],
                },
                "uuid": "u-first",
            },
            {
                "type": "assistant",
                "message": {
                    "role": "assistant",
                    "content": [{"type": "text", "text": "last"}],
                },
                "uuid": "u-last",
            },
        ]
        line, text = audit_extract.last_text_message(turn_lines)
        self.assertEqual(text, "last")
        self.assertEqual(line["uuid"], "u-last")

    def test_no_text_bearing_message_returns_none_none(self):
        self.assertEqual(audit_extract.last_text_message([]), (None, None))


if __name__ == "__main__":
    unittest.main()
