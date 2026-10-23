import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import context_measure


def assistant_line(message_id, blocks, uuid=None, sidechain=False):
    record = {"type": "assistant", "message": {"content": blocks}}
    if message_id is not None:
        record["message"]["id"] = message_id
    if uuid is not None:
        record["uuid"] = uuid
    if sidechain:
        record["isSidechain"] = True
    return record


def human_prompt(text, uuid=None, sidechain=False):
    record = {"type": "user", "message": {"role": "user", "content": text}}
    if uuid is not None:
        record["uuid"] = uuid
    if sidechain:
        record["isSidechain"] = True
    return record


def tool_result_record(tool_use_id, content, uuid=None, sidechain=False):
    record = {
        "type": "user",
        "message": {
            "role": "user",
            "content": [
                {"type": "tool_result", "tool_use_id": tool_use_id, "content": content}
            ],
        },
    }
    if uuid is not None:
        record["uuid"] = uuid
    if sidechain:
        record["isSidechain"] = True
    return record


def tool_use_block(block_id, name, tool_input):
    return {"type": "tool_use", "id": block_id, "name": name, "input": tool_input}


class ContextMeasureTest(unittest.TestCase):
    def write_lines(self, lines):
        handle = tempfile.NamedTemporaryFile(
            mode="w", suffix=".jsonl", delete=False, encoding="utf-8"
        )
        handle.write("\n".join(lines) + "\n")
        handle.close()
        self.addCleanup(os.remove, handle.name)
        return handle.name

    def test_distinct_blocks_across_lines_of_one_message_each_count_once(self):
        records = [
            assistant_line("msg_1", [{"type": "thinking", "thinking": "abc"}]),
            assistant_line("msg_1", [{"type": "text", "text": "hello"}]),
            assistant_line("msg_1", [tool_use_block("toolu_1", "Read", {"a": 1})]),
        ]
        totals = context_measure.measure(records)["totals"]["buckets"]
        self.assertEqual(totals["assistant_thinking"], 3)
        self.assertEqual(totals["assistant_text"], 5)
        self.assertEqual(totals["assistant_tool_use_input"], len('{"a": 1}'))

    def test_same_block_repeated_on_two_lines_of_one_message_counts_once(self):
        records = [
            assistant_line("msg_1", [{"type": "text", "text": "hello"}]),
            assistant_line("msg_1", [{"type": "text", "text": "hello"}]),
        ]
        totals = context_measure.measure(records)["totals"]["buckets"]
        self.assertEqual(totals["assistant_text"], 5)

    def test_assistant_record_without_message_id_counts_per_line(self):
        records = [
            assistant_line(None, [{"type": "text", "text": "hi"}]),
            assistant_line(None, [{"type": "text", "text": "hi"}]),
        ]
        totals = context_measure.measure(records)["totals"]["buckets"]
        self.assertEqual(totals["assistant_text"], 4)

    def test_tool_result_string_and_list_content_count_and_tool_result_is_ignored(self):
        records = [
            tool_result_record("toolu_1", "result text", uuid="u1"),
            tool_result_record(
                "toolu_2",
                [{"type": "text", "text": "abc"}, {"type": "text", "text": "de"}],
                uuid="u2",
            ),
            {
                "type": "user",
                "uuid": "u3",
                "message": {"role": "user", "content": []},
                "toolUseResult": {"stdout": "x" * 100},
            },
        ]
        totals = context_measure.measure(records)["totals"]["buckets"]
        self.assertEqual(totals["tool_results"], len("result text") + 5)

    def test_tool_results_split_by_tool_name_via_tool_use_id(self):
        records = [
            assistant_line("msg_1", [tool_use_block("toolu_A", "Read", {})]),
            tool_result_record("toolu_A", "12345", uuid="u1"),
            assistant_line("msg_2", [tool_use_block("toolu_B", "Bash", {})]),
            tool_result_record("toolu_B", "123", uuid="u2"),
        ]
        measured = context_measure.measure(records)
        self.assertEqual(measured["totals"]["tools"], {"Read": 5, "Bash": 3})
        self.assertEqual(measured["totals"]["buckets"]["tool_results"], 8)

    def test_tool_result_without_matching_tool_use_goes_to_unknown_tool(self):
        records = [tool_result_record("toolu_missing", "abcd", uuid="u1")]
        measured = context_measure.measure(records)
        self.assertEqual(measured["totals"]["tools"], {"unknown_tool": 4})

    def test_sidechain_records_are_excluded(self):
        records = [
            assistant_line("msg_1", [{"type": "text", "text": "secret"}], sidechain=True),
            human_prompt("sidechain prompt", sidechain=True),
            tool_result_record("toolu_1", "side result", sidechain=True),
        ]
        measured = context_measure.measure(records)
        self.assertEqual(len(measured["turns"]), 1)
        self.assertEqual(measured["totals"]["buckets"]["assistant_text"], 0)
        self.assertEqual(measured["totals"]["buckets"]["user_text"], 0)
        self.assertEqual(measured["totals"]["buckets"]["tool_results"], 0)

    def test_two_human_prompts_give_turns_zero_one_two_with_right_characters(self):
        records = [
            human_prompt("first", uuid="p1"),
            assistant_line("msg_1", [{"type": "text", "text": "aa"}]),
            human_prompt("second!", uuid="p2"),
            assistant_line("msg_2", [{"type": "text", "text": "bbb"}]),
        ]
        turns = context_measure.measure(records)["turns"]
        self.assertEqual([turn["turn"] for turn in turns], [0, 1, 2])
        self.assertEqual(turns[0]["buckets"]["user_text"], 0)
        self.assertEqual(turns[0]["buckets"]["assistant_text"], 0)
        self.assertEqual(turns[1]["buckets"]["user_text"], 5)
        self.assertEqual(turns[1]["buckets"]["assistant_text"], 2)
        self.assertEqual(turns[2]["buckets"]["user_text"], 7)
        self.assertEqual(turns[2]["buckets"]["assistant_text"], 3)

    def test_file_with_zero_human_prompts_yields_only_turn_zero(self):
        records = [assistant_line("msg_1", [{"type": "text", "text": "solo"}])]
        turns = context_measure.measure(records)["turns"]
        self.assertEqual([turn["turn"] for turn in turns], [0])
        self.assertEqual(turns[0]["buckets"]["assistant_text"], 4)

    def test_records_missing_uuid_origin_and_message_id_do_not_crash(self):
        records = [
            human_prompt("no uuid here"),
            {"type": "assistant"},
            {"type": "assistant", "message": {"content": "not a list"}},
            assistant_line(None, [{"type": "text", "text": "ok"}]),
            tool_result_record("toolu_1", "res"),
            {"type": "user", "message": {"role": "user", "content": "x", "origin": None}},
            "not a dict",
        ]
        measured = context_measure.measure(records)
        self.assertEqual(measured["totals"]["buckets"]["user_text"], len("no uuid here") + len("x"))
        self.assertEqual(measured["totals"]["buckets"]["assistant_text"], 2)
        self.assertEqual(measured["totals"]["buckets"]["tool_results"], 3)

    def test_user_record_with_repeated_uuid_counts_once(self):
        records = [
            human_prompt("repeat", uuid="dup"),
            human_prompt("repeat", uuid="dup"),
        ]
        measured = context_measure.measure(records)
        self.assertEqual(len(measured["turns"]), 2)
        self.assertEqual(measured["totals"]["buckets"]["user_text"], len("repeat"))

    def test_load_records_skips_and_counts_malformed_line(self):
        path = self.write_lines(
            [
                json.dumps({"type": "user", "uuid": "a", "message": {"content": "one"}}),
                "{not valid json",
                json.dumps({"type": "user", "uuid": "b", "message": {"content": "two"}}),
            ]
        )
        records, malformed = context_measure.load_records(path)
        self.assertEqual(malformed, 1)
        self.assertEqual([record["uuid"] for record in records], ["a", "b"])

    def test_non_human_string_user_records_do_not_count_as_user_text(self):
        records = [
            {
                "type": "user",
                "uuid": "peer1",
                "message": {"role": "user", "content": "handback body"},
                "origin": {"kind": "peer", "handback": True},
            },
            {
                "type": "user",
                "uuid": "meta1",
                "isMeta": True,
                "message": {"role": "user", "content": "harness text"},
            },
        ]
        measured = context_measure.measure(records)
        self.assertEqual(len(measured["turns"]), 1)
        self.assertEqual(measured["totals"]["buckets"]["user_text"], 0)


if __name__ == "__main__":
    unittest.main()
