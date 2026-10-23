import contextlib
import io
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


def attachment_line(attachment, uuid=None):
    record = {"type": "attachment", "attachment": attachment}
    if uuid is not None:
        record["uuid"] = uuid
    return record


def user_record(content, uuid=None, origin=None, is_meta=False, compact=False):
    record = {"type": "user", "message": {"role": "user", "content": content}}
    if uuid is not None:
        record["uuid"] = uuid
    if origin is not None:
        record["origin"] = origin
    if is_meta:
        record["isMeta"] = True
    if compact:
        record["isCompactSummary"] = True
    return record


def bucket_totals(records):
    return context_measure.measure(records)["totals"]["buckets"]


HANDBACK_TEXT = '<agent-message from="agent_a">\n[Subagent hand-back] result one'
OTHER_HANDBACK_TEXT = '<agent-message from="agent_a">\n[Subagent hand-back] result two'


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

    def test_session_start_hook_counts_in_hook_session_start(self):
        records = [
            attachment_line(
                {"type": "hook_additional_context", "content": ["aaa"], "hookEvent": "SessionStart"}
            )
        ]
        self.assertEqual(bucket_totals(records)["hook_session_start"], 3)

    def test_user_prompt_submit_hook_counts_in_hook_user_prompt(self):
        records = [
            attachment_line(
                {"type": "hook_additional_context", "content": ["bb"], "hookEvent": "UserPromptSubmit"}
            )
        ]
        self.assertEqual(bucket_totals(records)["hook_user_prompt"], 2)

    def test_other_hook_event_counts_in_hook_other(self):
        records = [
            attachment_line(
                {"type": "hook_additional_context", "content": ["c"], "hookEvent": "PreToolUse"}
            )
        ]
        self.assertEqual(bucket_totals(records)["hook_other"], 1)

    def test_hook_without_hook_event_counts_in_hook_other(self):
        records = [attachment_line({"type": "hook_additional_context", "content": ["abc"]})]
        self.assertEqual(bucket_totals(records)["hook_other"], 3)

    def test_hook_content_list_of_two_strings_sums_both(self):
        records = [
            attachment_line(
                {"type": "hook_additional_context", "content": ["abc", "de"], "hookEvent": "SessionStart"}
            )
        ]
        self.assertEqual(bucket_totals(records)["hook_session_start"], 5)

    def test_total_tokens_reminder_counts_text_and_not_type_value(self):
        text = "<total_tokens>1</total_tokens>"
        records = [attachment_line({"type": "total_tokens_reminder", "text": text})]
        other = bucket_totals(records)["other_harness"]
        self.assertEqual(other, len(text))

    def test_peer_user_record_counts_in_handbacks(self):
        records = [user_record(HANDBACK_TEXT, uuid="p1", origin={"kind": "peer", "handback": True})]
        measured = context_measure.measure(records)
        self.assertEqual(measured["totals"]["buckets"]["handbacks"], len(HANDBACK_TEXT))
        self.assertEqual(len(measured["turns"]), 1)

    def test_same_handback_as_peer_record_and_queued_command_counts_once(self):
        records = [
            user_record(HANDBACK_TEXT, uuid="p1", origin={"kind": "peer", "handback": True}),
            attachment_line(
                {
                    "type": "queued_command",
                    "prompt": HANDBACK_TEXT,
                    "origin": {"kind": "peer", "handback": True},
                },
                uuid="a1",
            ),
        ]
        self.assertEqual(bucket_totals(records)["handbacks"], len(HANDBACK_TEXT))

    def test_two_different_handbacks_both_count(self):
        records = [
            user_record(HANDBACK_TEXT, uuid="p1", origin={"kind": "peer", "handback": True}),
            user_record(OTHER_HANDBACK_TEXT, uuid="p2", origin={"kind": "peer", "handback": True}),
        ]
        expected = len(HANDBACK_TEXT) + len(OTHER_HANDBACK_TEXT)
        self.assertEqual(bucket_totals(records)["handbacks"], expected)

    def test_queued_command_without_peer_origin_counts_in_other_harness(self):
        records = [attachment_line({"type": "queued_command", "prompt": "do this"})]
        measured = context_measure.measure(records)["totals"]["buckets"]
        self.assertEqual(measured["other_harness"], len("do this"))
        self.assertEqual(measured["handbacks"], 0)

    def test_task_notification_by_origin_counts_in_notifications(self):
        body = "<task-notification>done</task-notification>"
        records = [user_record(body, uuid="n1", origin={"kind": "task-notification"})]
        self.assertEqual(bucket_totals(records)["notifications"], len(body))

    def test_task_notification_by_string_prefix_counts_in_notifications(self):
        body = "<task-notification>done</task-notification>"
        records = [user_record(body, uuid="n2")]
        self.assertEqual(bucket_totals(records)["notifications"], len(body))

    def test_skill_body_counts_in_skill_bodies(self):
        body = "Base directory for this skill: /x"
        records = [user_record(body, uuid="s1", is_meta=True)]
        self.assertEqual(bucket_totals(records)["skill_bodies"], len(body))

    def test_other_meta_string_counts_in_other_harness(self):
        records = [user_record("harness text", uuid="m1", is_meta=True)]
        self.assertEqual(bucket_totals(records)["other_harness"], len("harness text"))

    def test_compaction_summary_counts_in_compaction_summary_and_not_user_text(self):
        records = [user_record("summary text", uuid="c1", compact=True)]
        buckets = bucket_totals(records)
        self.assertEqual(buckets["compaction_summary"], len("summary text"))
        self.assertEqual(buckets["user_text"], 0)

    def test_mode_and_other_record_types_add_nothing(self):
        records = [
            {"type": "mode", "uuid": "x1", "value": "plan"},
            {"type": "last-prompt", "uuid": "x2", "text": "abc"},
        ]
        measured = context_measure.measure(records)
        self.assertEqual(set(measured["totals"]["buckets"].values()), {0})
        self.assertEqual(len(measured["turns"]), 1)

    def test_attachment_without_dict_or_non_dict_does_not_crash(self):
        records = [
            {"type": "attachment"},
            {"type": "attachment", "attachment": "oops"},
            {"type": "attachment", "attachment": ["x"]},
        ]
        self.assertEqual(set(bucket_totals(records).values()), {0})

    def test_rendered_attachment_counts_rendered_text_and_not_attachment_strings(self):
        record = attachment_line({"type": "total_tokens_reminder", "text": "IGNORED TEXT"})
        record["rendered"] = [{"content": "<system-reminder>xy"}]
        self.assertEqual(bucket_totals([record])["other_harness"], len("<system-reminder>xy"))

    def test_rendered_item_without_string_content_counts_its_json_length(self):
        record = attachment_line({"type": "total_tokens_reminder", "text": "IGNORED TEXT"})
        record["rendered"] = ["plain", {"content": 5}]
        expected = len(json.dumps("plain", sort_keys=True)) + len(
            json.dumps({"content": 5}, sort_keys=True)
        )
        self.assertEqual(bucket_totals([record])["other_harness"], expected)

    def test_hook_success_without_rendered_counts_zero(self):
        records = [attachment_line({"type": "hook_success", "content": "ran hook output"})]
        self.assertEqual(bucket_totals(records)["other_harness"], 0)

    def test_prompt_snapshot_without_rendered_counts_zero(self):
        records = [attachment_line({"type": "prompt_snapshot", "text": "snapshot text"})]
        self.assertEqual(bucket_totals(records)["other_harness"], 0)

    def test_subtype_without_rendered_and_not_listed_still_walks_strings(self):
        text = "<total_tokens>1</total_tokens>"
        records = [attachment_line({"type": "total_tokens_reminder", "text": text})]
        self.assertEqual(bucket_totals(records)["other_harness"], len(text))


def write_bytes(data):
    handle = tempfile.NamedTemporaryFile(suffix=".jsonl", delete=False)
    handle.write(data)
    handle.close()
    return handle.name


class CliTest(unittest.TestCase):
    def write_lines(self, lines):
        return self.write_file(("\n".join(lines) + "\n").encode("utf-8"))

    def write_file(self, data):
        path = write_bytes(data)
        self.addCleanup(os.remove, path)
        return path

    def run_main(self, argv):
        out = io.StringIO()
        err = io.StringIO()
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            code = context_measure.main(argv)
        return code, out.getvalue(), err.getvalue()

    def sample_path(self):
        return self.write_lines(
            [
                json.dumps(human_prompt("hello", uuid="p1")),
                json.dumps(
                    assistant_line(
                        "msg_1", [tool_use_block("toolu_1", "Read", {"file": "a"})]
                    )
                ),
                json.dumps(tool_result_record("toolu_1", "file body", uuid="r1")),
                "{broken",
                json.dumps(assistant_line("msg_2", [{"type": "text", "text": "done"}])),
            ]
        )

    def test_default_report_has_header_buckets_tools_and_top_turns(self):
        code, out, _ = self.run_main([self.sample_path()])
        self.assertEqual(code, 0)
        self.assertIn("Records: 4", out)
        self.assertIn("Malformed lines: 1", out)
        self.assertIn("Turns: 2", out)
        for name in context_measure.BUCKETS:
            self.assertIn(name, out)
        self.assertIn("all sources", out)
        self.assertIn("Tool results by tool", out)
        self.assertRegex(out, r"(?m)^Read\s+\d+")
        self.assertIn("Top 5 turns by size", out)

    def test_percent_column_uses_one_decimal_of_grand_total(self):
        path = self.write_lines(
            [
                json.dumps(human_prompt("a")),
                json.dumps(assistant_line("msg_1", [{"type": "text", "text": "bbb"}])),
            ]
        )
        code, out, _ = self.run_main([path])
        self.assertEqual(code, 0)
        rows = {line.split()[0]: line.split() for line in out.splitlines() if line.strip()}
        self.assertEqual(rows["user_text"][-2:], ["1", "25.0%"])
        self.assertEqual(rows["assistant_text"][-2:], ["3", "75.0%"])
        self.assertEqual(rows["all"][-2:], ["4", "100.0%"])

    def test_zero_grand_total_reports_zero_percent(self):
        path = self.write_lines(
            [json.dumps({"type": "mode", "uuid": "m1", "value": "plan"})]
        )
        code, out, _ = self.run_main([path])
        self.assertEqual(code, 0)
        rows = {line.split()[0]: line.split() for line in out.splitlines() if line.strip()}
        self.assertEqual(rows["all"][-2:], ["0", "0.0%"])

    def test_top_two_lists_exactly_two_turns(self):
        lines = []
        for index in range(4):
            lines.append(json.dumps(human_prompt("p" * (index + 1), uuid="p%d" % index)))
            lines.append(
                json.dumps(
                    assistant_line(
                        "msg_%d" % index, [{"type": "text", "text": "x" * (index * 10)}]
                    )
                )
            )
        path = self.write_lines(lines)
        code, out, _ = self.run_main([path, "--top", "2"])
        self.assertEqual(code, 0)
        self.assertIn("Top 2 turns by size", out)
        turn_rows = [line for line in out.splitlines() if line.strip().startswith("turn ")]
        self.assertEqual(len(turn_rows), 2)

    def test_top_zero_and_non_integer_exit_two(self):
        path = self.sample_path()
        for bad in ("0", "abc", "-3"):
            with self.subTest(top=bad):
                with contextlib.redirect_stderr(io.StringIO()):
                    with self.assertRaises(SystemExit) as ctx:
                        context_measure.main([path, "--top", bad])
                self.assertEqual(ctx.exception.code, 2)

    def test_json_output_has_five_keys_and_matches_measure_totals(self):
        path = self.sample_path()
        code, out, _ = self.run_main([path, "--json"])
        self.assertEqual(code, 0)
        data = json.loads(out)
        self.assertEqual(
            set(data), {"path", "records", "malformed_lines", "totals", "turns"}
        )
        records, _ = context_measure.load_records(path)
        self.assertEqual(data["totals"], context_measure.measure(records)["totals"])
        self.assertEqual(data["records"], 4)
        self.assertEqual(data["malformed_lines"], 1)

    def test_missing_path_exits_two_with_error_on_stderr(self):
        gone = write_bytes(b"")
        os.remove(gone)
        code, out, err = self.run_main([gone])
        self.assertEqual(code, 2)
        self.assertEqual(out, "")
        self.assertTrue(err.startswith("error:"))

    def test_zero_byte_file_exits_two(self):
        code, out, err = self.run_main([self.write_file(b"")])
        self.assertEqual(code, 2)
        self.assertEqual(out, "")
        self.assertTrue(err.startswith("error:"))

    def test_file_of_only_malformed_lines_exits_two(self):
        path = self.write_lines(["{not json", "also not json"])
        code, out, err = self.run_main([path])
        self.assertEqual(code, 2)
        self.assertEqual(out, "")
        self.assertTrue(err.startswith("error:"))

    def test_one_good_record_and_one_malformed_line_exits_zero(self):
        path = self.write_lines([json.dumps(human_prompt("hi")), "{bad"])
        code, out, _ = self.run_main([path])
        self.assertEqual(code, 0)
        self.assertIn("Malformed lines: 1", out)

    def test_text_report_is_ascii_even_with_non_ascii_tool_name(self):
        name = "R" + chr(0xE9) + "sum" + chr(0xE9)
        path = self.write_lines(
            [
                json.dumps(assistant_line("msg_1", [tool_use_block("toolu_1", name, {})])),
                json.dumps(tool_result_record("toolu_1", "body")),
            ]
        )
        code, out, _ = self.run_main([path])
        self.assertEqual(code, 0)
        self.assertTrue(out.isascii())
        self.assertIn(ascii(name)[1:-1], out)


def system_record(subtype, uuid=None, sidechain=False):
    record = {"type": "system", "subtype": subtype}
    if uuid is not None:
        record["uuid"] = uuid
    if sidechain:
        record["isSidechain"] = True
    return record


def compact_boundary(uuid=None):
    return system_record("compact_boundary", uuid)


def skill_block(block_id, skill_name):
    return tool_use_block(block_id, "Skill", {"skill": skill_name})


def text_block(text):
    return {"type": "text", "text": text}


class BehaviourTest(unittest.TestCase):
    def test_every_banned_phrase_is_reported_with_zero_on_empty_input(self):
        behaviour = context_measure.behaviour([])
        self.assertEqual(
            behaviour["banned"], {phrase: 0 for phrase in context_measure.BANNED_PHRASES}
        )
        self.assertEqual(behaviour["banned_total"], 0)
        self.assertEqual(behaviour["assistant_text_chars"], 0)
        self.assertEqual(behaviour["banned_per_10k_chars"], 0.0)
        self.assertEqual(behaviour["skill_calls"], 0)
        self.assertEqual(behaviour["skills"], {})
        self.assertEqual(behaviour["compactions"], 0)
        self.assertEqual(behaviour["reload_checks"], [])
        self.assertEqual(behaviour["reload_misses"], 0)

    def test_phrase_counts_case_insensitively_on_word_boundaries(self):
        records = [assistant_line("msg_1", [text_block("Should work. unshould worked")])]
        banned = context_measure.behaviour(records)["banned"]
        self.assertEqual(banned["should work"], 1)
        self.assertEqual(banned["that should do it"], 0)

    def test_phrase_inside_fenced_code_is_skipped_and_outside_is_counted(self):
        text = "```\nshould work\n```\nand should work here"
        records = [assistant_line("msg_1", [text_block(text)])]
        self.assertEqual(context_measure.behaviour(records)["banned"]["should work"], 1)

    def test_curly_apostrophe_matches_straight_apostrophe_phrase(self):
        records = [assistant_line("msg_1", [text_block("I\u2019m sure")])]
        self.assertEqual(context_measure.behaviour(records)["banned"]["i'm sure"], 1)

    def test_load_bearing_and_hyphenated_are_counted_separately(self):
        records = [assistant_line("msg_1", [text_block("load bearing and load-bearing")])]
        banned = context_measure.behaviour(records)["banned"]
        self.assertEqual(banned["load bearing"], 1)
        self.assertEqual(banned["load-bearing"], 1)

    def test_rate_is_hand_computed_per_ten_thousand_characters(self):
        records = [assistant_line("msg_1", [text_block("should work")])]
        behaviour = context_measure.behaviour(records)
        self.assertEqual(behaviour["assistant_text_chars"], 11)
        self.assertEqual(behaviour["banned_total"], 1)
        self.assertEqual(behaviour["banned_per_10k_chars"], 909.09)

    def test_skill_calls_strip_plugin_prefix_and_skip_blocks_without_skill_name(self):
        records = [
            assistant_line("msg_1", [skill_block("t1", "anthropic-skills:pdf")]),
            assistant_line("msg_2", [tool_use_block("t2", "Skill", {})]),
            assistant_line("msg_3", [skill_block("t3", "pdf")]),
        ]
        behaviour = context_measure.behaviour(records)
        self.assertEqual(behaviour["skill_calls"], 3)
        self.assertEqual(behaviour["skills"], {"pdf": 2})

    def test_repeated_assistant_block_counts_once(self):
        records = [
            assistant_line("msg_1", [text_block("hello")]),
            assistant_line("msg_1", [text_block("hello")]),
            assistant_line("msg_2", [skill_block("t1", "honesty")]),
            assistant_line("msg_2", [skill_block("t1", "honesty")]),
        ]
        behaviour = context_measure.behaviour(records)
        self.assertEqual(behaviour["assistant_text_chars"], 5)
        self.assertEqual(behaviour["skill_calls"], 1)

    def test_two_compactions_with_reload_checks_and_one_miss(self):
        records = [
            compact_boundary("c1"),
            assistant_line("msg_1", [skill_block("t1", "honesty")]),
            assistant_line("msg_2", [skill_block("t2", "communication")]),
            assistant_line("msg_3", [tool_use_block("t3", "Edit", {})]),
            compact_boundary("c2"),
            assistant_line("msg_4", [skill_block("t4", "honesty")]),
            assistant_line("msg_5", [tool_use_block("t5", "Agent", {})]),
        ]
        behaviour = context_measure.behaviour(records)
        self.assertEqual(behaviour["compactions"], 2)
        self.assertEqual(
            behaviour["reload_checks"],
            [
                {
                    "compaction": 1,
                    "honesty": True,
                    "communication": True,
                    "first_gated_tool": "Edit",
                },
                {
                    "compaction": 2,
                    "honesty": True,
                    "communication": False,
                    "first_gated_tool": "Agent",
                },
            ],
        )
        self.assertEqual(behaviour["reload_misses"], 1)

    def test_skill_after_first_gated_tool_does_not_count_for_reload(self):
        records = [
            compact_boundary("c1"),
            assistant_line("msg_1", [tool_use_block("t1", "Write", {})]),
            assistant_line("msg_2", [skill_block("t2", "honesty")]),
            assistant_line("msg_3", [skill_block("t3", "communication")]),
        ]
        check = context_measure.behaviour(records)["reload_checks"][0]
        self.assertFalse(check["honesty"])
        self.assertFalse(check["communication"])
        self.assertEqual(check["first_gated_tool"], "Write")

    def test_compaction_as_last_record_reports_end_of_transcript_and_misses(self):
        behaviour = context_measure.behaviour([compact_boundary("c1")])
        self.assertEqual(
            behaviour["reload_checks"],
            [
                {
                    "compaction": 1,
                    "honesty": False,
                    "communication": False,
                    "first_gated_tool": "end_of_transcript",
                }
            ],
        )
        self.assertEqual(behaviour["reload_misses"], 1)

    def test_no_compaction_gives_empty_reload_checks(self):
        records = [assistant_line("msg_1", [skill_block("t1", "honesty")])]
        behaviour = context_measure.behaviour(records)
        self.assertEqual(behaviour["compactions"], 0)
        self.assertEqual(behaviour["reload_checks"], [])
        self.assertEqual(behaviour["reload_misses"], 0)

    def test_sidechain_assistant_and_compaction_records_are_excluded(self):
        records = [
            assistant_line(
                "msg_1",
                [text_block("secret"), skill_block("t1", "honesty")],
                sidechain=True,
            ),
            system_record("compact_boundary", "c1", sidechain=True),
        ]
        behaviour = context_measure.behaviour(records)
        self.assertEqual(behaviour["assistant_text_chars"], 0)
        self.assertEqual(behaviour["skill_calls"], 0)
        self.assertEqual(behaviour["compactions"], 0)


class BehaviourCliTest(unittest.TestCase):
    def write_lines(self, lines):
        path = write_bytes(("\n".join(lines) + "\n").encode("utf-8"))
        self.addCleanup(os.remove, path)
        return path

    def run_main(self, argv):
        out = io.StringIO()
        with contextlib.redirect_stdout(out):
            code = context_measure.main(argv)
        return code, out.getvalue()

    def sample_path(self):
        return self.write_lines(
            [
                json.dumps(human_prompt("should work", uuid="p1")),
                json.dumps(assistant_line("msg_1", [text_block("I'm sure")])),
                json.dumps(assistant_line("msg_2", [skill_block("t1", "communication")])),
                json.dumps(compact_boundary("c1")),
                json.dumps(assistant_line("msg_3", [skill_block("t2", "honesty")])),
                json.dumps(assistant_line("msg_4", [tool_use_block("t3", "Edit", {})])),
            ]
        )

    def test_behaviour_flag_adds_text_section(self):
        code, out = self.run_main([self.sample_path(), "--behaviour"])
        self.assertEqual(code, 0)
        self.assertIn("Behaviour baseline", out)
        self.assertIn("Banned phrases: ", out)
        self.assertIn("compaction 1: honesty=yes communication=no first_gated_tool=Edit", out)
        self.assertTrue(out.isascii())

    def test_behaviour_flag_adds_key_to_json(self):
        code, out = self.run_main([self.sample_path(), "--json", "--behaviour"])
        self.assertEqual(code, 0)
        data = json.loads(out)
        self.assertIn("behaviour", data)
        self.assertIn("turns", data)
        self.assertEqual(data["behaviour"]["compactions"], 1)

    def test_default_output_without_flag_has_no_behaviour_section(self):
        path = self.sample_path()
        code, out = self.run_main([path])
        self.assertEqual(code, 0)
        records, malformed = context_measure.load_records(path)
        expected = context_measure.format_report(
            path, len(records), malformed, context_measure.measure(records), 5
        )
        self.assertEqual(out, expected)
        self.assertNotIn("Behaviour baseline", out)


if __name__ == "__main__":
    unittest.main()
