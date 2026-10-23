"""Measure what fills a Claude Code session's main-thread context, per turn.

Reads a session transcript (JSON Lines) and reports characters per bucket.
Subagent records (isSidechain true) are excluded. Turn 0 holds everything
before the first human prompt; turn N starts at the Nth human prompt."""
import argparse
import hashlib
import json
import os
import re
import sys

BUCKETS = (
    "hook_session_start",
    "hook_user_prompt",
    "hook_other",
    "other_harness",
    "tool_results",
    "handbacks",
    "notifications",
    "assistant_text",
    "assistant_thinking",
    "assistant_tool_use_input",
    "user_text",
    "skill_bodies",
    "compaction_summary",
)
UNKNOWN_TOOL = "unknown_tool"
HOOK_BUCKETS = {
    "SessionStart": "hook_session_start",
    "UserPromptSubmit": "hook_user_prompt",
}
SKILL_BODY_PREFIX = "Base directory for this skill"
NOTIFICATION_PREFIX = "<task-notification>"
HANDBACK_MARKER = "[Subagent hand-back]"
HANDBACK_FROM = 'from="'
NON_TEXT_KEYS = ("type", "toolUseID")
NOT_INJECTED_SUBTYPES = (
    "hook_success",
    "prompt_snapshot",
    "command_permissions",
    "deferred_tools_record",
    "thinking_drop",
)
# The first six phrases are the unconditional bans in the honesty skill
# (skills/honesty/SKILL.md); the rest are the punchy-phrasing examples in the
# communication skill (skills/communication/SKILL.md). The list is a fixed
# constant so a baseline and a later measure use the same words.
BANNED_PHRASES = (
    "should work",
    "that should do it",
    "i'm confident",
    "i'm sure",
    "i'm fairly confident",
    "probably passes",
    "load-bearing",
    "load bearing",
    "crucially",
    "the deeper point",
    "a real win",
    "elegant",
)
FENCED_CODE = re.compile(r"```.*?```", re.DOTALL)
GATED_TOOLS = ("Edit", "Write", "NotebookEdit", "Agent")
RELOAD_SKILLS = ("honesty", "communication")
COMPACT_BOUNDARY = "compact_boundary"
END_OF_TRANSCRIPT = "end_of_transcript"


def phrase_pattern(phrase):
    """Case-insensitive pattern for one phrase: no ASCII letter or digit may touch
    either end, and an apostrophe matches a straight or a curly one."""
    body = r"['\u2019]".join(re.escape(part) for part in phrase.split("'"))
    return re.compile(
        r"(?<![A-Za-z0-9])" + body + r"(?![A-Za-z0-9])",
        re.IGNORECASE | re.ASCII,
    )


BANNED_PATTERNS = tuple((phrase, phrase_pattern(phrase)) for phrase in BANNED_PHRASES)


def load_records(path):
    """Return (records, malformed_count). Lines that are not JSON objects are
    skipped and counted; the file is read line by line."""
    records = []
    malformed = 0
    with open(path, "rb") as handle:
        for raw_line in handle:
            try:
                record = json.loads(raw_line.decode("utf-8"))
            except (UnicodeDecodeError, ValueError):
                malformed += 1
                continue
            if isinstance(record, dict):
                records.append(record)
            else:
                malformed += 1
    return records, malformed


def new_turn(turn_number):
    return {
        "turn": turn_number,
        "buckets": {name: 0 for name in BUCKETS},
        "tools": {},
    }


def add_chars(turn, bucket, count):
    turn["buckets"][bucket] += count


def add_tool_result(turn, tool_name, count):
    turn["buckets"]["tool_results"] += count
    turn["tools"][tool_name] = turn["tools"].get(tool_name, 0) + count


def dumps_length(value):
    try:
        return len(json.dumps(value, sort_keys=True))
    except (TypeError, ValueError):
        return 0


def text_blocks_length(blocks):
    return sum(
        len(block["text"])
        for block in blocks
        if isinstance(block, dict)
        and block.get("type") == "text"
        and isinstance(block.get("text"), str)
    )


def tool_result_length(content):
    if isinstance(content, str):
        return len(content)
    if isinstance(content, list):
        return text_blocks_length(content)
    return 0


def message_text(content):
    """All text of a message content: the string itself, or the text blocks joined."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "".join(
            block["text"]
            for block in content
            if isinstance(block, dict)
            and block.get("type") == "text"
            and isinstance(block.get("text"), str)
        )
    return ""


def first_text(content):
    """The string content, or the text of the first text block."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        for block in content:
            if (
                isinstance(block, dict)
                and block.get("type") == "text"
                and isinstance(block.get("text"), str)
            ):
                return block["text"]
    return ""


def is_origin_kind(origin, kind):
    return isinstance(origin, dict) and origin.get("kind") == kind


def string_chars(value):
    """Sum of len() of every string value inside value, skipping NON_TEXT_KEYS."""
    if isinstance(value, str):
        return len(value)
    if isinstance(value, dict):
        return sum(
            string_chars(item)
            for key, item in value.items()
            if key not in NON_TEXT_KEYS
        )
    if isinstance(value, list):
        return sum(string_chars(item) for item in value)
    return 0


def rendered_chars(rendered):
    """Characters of the text the harness rendered for the model: the content
    string of each dict item, or the JSON length of any other item."""
    total = 0
    for item in rendered:
        if isinstance(item, dict) and isinstance(item.get("content"), str):
            total += len(item["content"])
        else:
            total += dumps_length(item)
    return total


def other_attachment_chars(record, attachment):
    """Characters an other_harness attachment injects into the model context."""
    rendered = record.get("rendered")
    if isinstance(rendered, list):
        return rendered_chars(rendered)
    if attachment.get("type") in NOT_INJECTED_SUBTYPES:
        return 0
    return string_chars(attachment)


def handback_key(text):
    """(sender, sha1 of the hand-back body). The sender is the text between the
    first 'from="' and the next quote; the body is the text after the first
    marker, or the whole text when the marker is absent."""
    sender = ""
    start = text.find(HANDBACK_FROM)
    if start != -1:
        begin = start + len(HANDBACK_FROM)
        end = text.find('"', begin)
        if end != -1:
            sender = text[begin:end]
    marker_at = text.find(HANDBACK_MARKER)
    if marker_at != -1:
        body = text[marker_at + len(HANDBACK_MARKER):]
    else:
        body = text
    digest = hashlib.sha1(body.encode("utf-8", "surrogatepass")).hexdigest()
    return (sender, digest)


def count_handback(turn, state, text):
    key = handback_key(text)
    if key in state["handbacks"]:
        return
    state["handbacks"].add(key)
    add_chars(turn, "handbacks", len(text))


def is_human_prompt(record):
    if record.get("isMeta") is True or record.get("isCompactSummary") is True:
        return False
    origin = record.get("origin")
    if origin is not None and not (
        isinstance(origin, dict) and origin.get("kind") == "human"
    ):
        return False
    content = record["message"].get("content")
    if isinstance(content, str):
        return True
    if isinstance(content, list):
        return not any(
            isinstance(block, dict) and block.get("type") == "tool_result"
            for block in content
        )
    return False


def count_user_prompt(turn, record):
    content = record["message"].get("content")
    if isinstance(content, str):
        add_chars(turn, "user_text", len(content))
    else:
        add_chars(turn, "user_text", text_blocks_length(content))


def count_tool_results(turn, content, tool_names):
    if not isinstance(content, list):
        return
    for block in content:
        if not isinstance(block, dict) or block.get("type") != "tool_result":
            continue
        tool_use_id = block.get("tool_use_id")
        tool_name = UNKNOWN_TOOL
        if isinstance(tool_use_id, str):
            tool_name = tool_names.get(tool_use_id, UNKNOWN_TOOL)
        add_tool_result(turn, tool_name, tool_result_length(block.get("content")))


def count_assistant(turn, record, tool_names, seen_blocks):
    message = record.get("message")
    if not isinstance(message, dict) or not isinstance(message.get("content"), list):
        return
    message_id = message.get("id")
    if not isinstance(message_id, str) or message_id == "":
        message_id = None
    for block in message["content"]:
        if not isinstance(block, dict):
            continue
        if message_id is not None:
            key = (message_id, json.dumps(block, sort_keys=True))
            if key in seen_blocks:
                continue
            seen_blocks.add(key)
        block_type = block.get("type")
        if block_type == "text" and isinstance(block.get("text"), str):
            add_chars(turn, "assistant_text", len(block["text"]))
        elif block_type == "thinking" and isinstance(block.get("thinking"), str):
            add_chars(turn, "assistant_thinking", len(block["thinking"]))
        elif block_type == "tool_use":
            tool_use_id = block.get("id")
            tool_name = block.get("name")
            if isinstance(tool_use_id, str) and isinstance(tool_name, str):
                tool_names[tool_use_id] = tool_name
            if "input" in block:
                add_chars(
                    turn, "assistant_tool_use_input", dumps_length(block["input"])
                )


def count_user_record(turns, record, state):
    message = record["message"]
    content = message.get("content")
    turn = turns[-1]
    if record.get("isCompactSummary") is True:
        add_chars(turn, "compaction_summary", len(message_text(content)))
        return
    origin = record.get("origin")
    if is_origin_kind(origin, "peer"):
        count_handback(turn, state, message_text(content))
        return
    if is_origin_kind(origin, "task-notification") or (
        isinstance(content, str) and content.startswith(NOTIFICATION_PREFIX)
    ):
        add_chars(turn, "notifications", len(message_text(content)))
        return
    if record.get("isMeta") is True:
        if first_text(content).startswith(SKILL_BODY_PREFIX):
            add_chars(turn, "skill_bodies", len(message_text(content)))
        else:
            add_chars(turn, "other_harness", len(message_text(content)))
        return
    if is_human_prompt(record):
        turns.append(new_turn(len(turns)))
        count_user_prompt(turns[-1], record)
        return
    count_tool_results(turn, content, state["tool_names"])


def count_attachment(turns, record, state):
    attachment = record.get("attachment")
    if not isinstance(attachment, dict):
        return
    turn = turns[-1]
    subtype = attachment.get("type")
    if subtype == "hook_additional_context":
        content = attachment.get("content")
        chars = 0
        if isinstance(content, list):
            chars = sum(len(item) for item in content if isinstance(item, str))
        event = attachment.get("hookEvent")
        bucket = HOOK_BUCKETS.get(event, "hook_other") if isinstance(event, str) else "hook_other"
        add_chars(turn, bucket, chars)
        return
    if subtype == "queued_command" and is_origin_kind(attachment.get("origin"), "peer"):
        prompt = attachment.get("prompt")
        count_handback(turn, state, prompt if isinstance(prompt, str) else "")
        return
    add_chars(turn, "other_harness", other_attachment_chars(record, attachment))


def sum_totals(turns):
    totals = {"buckets": {name: 0 for name in BUCKETS}, "tools": {}}
    for turn in turns:
        for name in BUCKETS:
            totals["buckets"][name] += turn["buckets"][name]
        for tool_name, count in turn["tools"].items():
            totals["tools"][tool_name] = totals["tools"].get(tool_name, 0) + count
    return totals


def measure(records):
    turns = [new_turn(0)]
    state = {
        "tool_names": {},
        "seen_blocks": set(),
        "seen_uuids": set(),
        "handbacks": set(),
    }
    for record in records:
        if not isinstance(record, dict) or record.get("isSidechain") is True:
            continue
        record_type = record.get("type")
        if record_type == "assistant":
            count_assistant(
                turns[-1], record, state["tool_names"], state["seen_blocks"]
            )
            continue
        if record_type not in ("user", "attachment"):
            continue
        uuid = record.get("uuid")
        if isinstance(uuid, str):
            if uuid in state["seen_uuids"]:
                continue
            state["seen_uuids"].add(uuid)
        if record_type == "user":
            if isinstance(record.get("message"), dict):
                count_user_record(turns, record, state)
        else:
            count_attachment(turns, record, state)
    return {"turns": turns, "totals": sum_totals(turns)}


def new_assistant_blocks(record, seen_blocks):
    """Content blocks of an assistant record not seen before, in order. Uses the
    same (message.id, block signature) dedup as count_assistant."""
    message = record.get("message")
    if not isinstance(message, dict) or not isinstance(message.get("content"), list):
        return []
    message_id = message.get("id")
    if not isinstance(message_id, str) or message_id == "":
        message_id = None
    fresh = []
    for block in message["content"]:
        if not isinstance(block, dict):
            continue
        if message_id is not None:
            key = (message_id, json.dumps(block, sort_keys=True))
            if key in seen_blocks:
                continue
            seen_blocks.add(key)
        fresh.append(block)
    return fresh


def skill_name(block):
    """The name of a Skill tool_use block with any plugin prefix removed, or None
    when input.skill is not a string."""
    tool_input = block.get("input")
    if not isinstance(tool_input, dict) or not isinstance(tool_input.get("skill"), str):
        return None
    return tool_input["skill"].rsplit(":", 1)[-1]


def banned_counts(text):
    """Banned-phrase hits in one text block, with fenced code removed."""
    visible = FENCED_CODE.sub("", text)
    return {phrase: len(pattern.findall(visible)) for phrase, pattern in BANNED_PATTERNS}


def behaviour(records):
    """Behaviour baseline over the main thread: banned phrases, Skill calls and
    the reload check after each compaction."""
    banned = {phrase: 0 for phrase in BANNED_PHRASES}
    text_chars = 0
    skill_calls = 0
    skills = {}
    checks = []
    scanning = False
    seen_blocks = set()
    seen_uuids = set()
    for record in records:
        if not isinstance(record, dict) or record.get("isSidechain") is True:
            continue
        record_type = record.get("type")
        if record_type == "system":
            if record.get("subtype") != COMPACT_BOUNDARY:
                continue
            uuid = record.get("uuid")
            if isinstance(uuid, str):
                if uuid in seen_uuids:
                    continue
                seen_uuids.add(uuid)
            checks.append(
                {
                    "compaction": len(checks) + 1,
                    "honesty": False,
                    "communication": False,
                    "first_gated_tool": END_OF_TRANSCRIPT,
                }
            )
            scanning = True
            continue
        if record_type != "assistant":
            continue
        for block in new_assistant_blocks(record, seen_blocks):
            block_type = block.get("type")
            if block_type == "text" and isinstance(block.get("text"), str):
                text_chars += len(block["text"])
                for phrase, count in banned_counts(block["text"]).items():
                    banned[phrase] += count
            elif block_type == "tool_use":
                name = block.get("name")
                skill = skill_name(block) if name == "Skill" else None
                if name == "Skill":
                    skill_calls += 1
                    if skill is not None:
                        skills[skill] = skills.get(skill, 0) + 1
                if not scanning or not checks:
                    continue
                check = checks[-1]
                if name in GATED_TOOLS:
                    check["first_gated_tool"] = name
                    scanning = False
                elif skill in RELOAD_SKILLS:
                    check[skill] = True
    banned_total = sum(banned.values())
    rate = round(banned_total * 10000 / text_chars, 2) if text_chars else 0.0
    misses = sum(1 for check in checks if not (check["honesty"] and check["communication"]))
    return {
        "assistant_text_chars": text_chars,
        "banned": banned,
        "banned_total": banned_total,
        "banned_per_10k_chars": rate,
        "skill_calls": skill_calls,
        "skills": skills,
        "compactions": len(checks),
        "reload_checks": checks,
        "reload_misses": misses,
    }


def format_behaviour(baseline):
    """The Behaviour baseline section, ready to append to the text report."""
    lines = [
        "Behaviour baseline",
        "Banned phrases: " + ", ".join(BANNED_PHRASES),
        "Assistant text characters: %d" % baseline["assistant_text_chars"],
        "Banned total: %d" % baseline["banned_total"],
        "Banned per 10k characters: %.2f" % baseline["banned_per_10k_chars"],
    ]
    rows = [
        [phrase, str(count)] for phrase, count in baseline["banned"].items() if count > 0
    ]
    if rows:
        lines.extend(render_table(["Phrase", "Count"], rows))
    else:
        lines.append("No banned phrases found.")
    lines.append("Skill calls: %d" % baseline["skill_calls"])
    top = sorted(baseline["skills"].items(), key=lambda item: (-item[1], item[0]))[:3]
    if top:
        lines.append(
            "Top skills: " + ", ".join("%s=%d" % (ascii_text(name), count) for name, count in top)
        )
    else:
        lines.append("Top skills: none")
    lines.append("Compactions: %d" % baseline["compactions"])
    for check in baseline["reload_checks"]:
        lines.append(
            "compaction %d: honesty=%s communication=%s first_gated_tool=%s"
            % (
                check["compaction"],
                "yes" if check["honesty"] else "no",
                "yes" if check["communication"] else "no",
                ascii_text(check["first_gated_tool"]),
            )
        )
    lines.append("Reload misses: %d" % baseline["reload_misses"])
    return "\n".join(lines) + "\n"


def ascii_text(value):
    """The value as ASCII-only text: non-ASCII characters become escapes."""
    return ascii(value)[1:-1]


def percent(part, whole):
    if whole == 0:
        return "0.0%"
    return "%.1f%%" % (100.0 * part / whole)


def render_row(cells, widths):
    padded = [cells[0].ljust(widths[0])]
    padded.extend(cell.rjust(width) for cell, width in zip(cells[1:], widths[1:]))
    return "  ".join(padded)


def render_table(headers, rows):
    """Header line then one line per row; first column left-aligned, others right-aligned."""
    widths = [len(cell) for cell in headers]
    for row in rows:
        widths = [max(width, len(cell)) for width, cell in zip(widths, row)]
    lines = [render_row(headers, widths)]
    lines.extend(render_row(row, widths) for row in rows)
    return lines


def turn_total(turn):
    return sum(turn["buckets"].values())


def top_buckets(turn, count=3):
    """The largest nonzero buckets of a turn; ties keep BUCKETS order."""
    nonzero = [(name, turn["buckets"][name]) for name in BUCKETS if turn["buckets"][name] > 0]
    nonzero.sort(key=lambda item: -item[1])
    return nonzero[:count]


def format_report(path, records_count, malformed, result, top):
    totals = result["totals"]["buckets"]
    grand_total = sum(totals[name] for name in BUCKETS)
    lines = [
        "Transcript: %s" % ascii_text(path),
        "Records: %d" % records_count,
        "Malformed lines: %d" % malformed,
        "Turns: %d" % len(result["turns"]),
        "",
        "Totals by source",
    ]
    source_rows = [
        [name, str(totals[name]), percent(totals[name], grand_total)] for name in BUCKETS
    ]
    source_rows.append(["all sources", str(grand_total), percent(grand_total, grand_total)])
    lines.extend(render_table(["Source", "Characters", "Percent"], source_rows))

    lines.append("")
    lines.append("Tool results by tool")
    tool_total = totals["tool_results"]
    tools = sorted(result["totals"]["tools"].items(), key=lambda item: (-item[1], item[0]))
    tool_rows = [
        [ascii_text(name), str(count), percent(count, tool_total)] for name, count in tools
    ]
    lines.extend(render_table(["Tool", "Characters", "Percent"], tool_rows))

    lines.append("")
    lines.append("Top %d turns by size" % top)
    ranked = sorted(result["turns"], key=lambda turn: (-turn_total(turn), turn["turn"]))
    for turn in ranked[:top]:
        details = ", ".join("%s=%d" % item for item in top_buckets(turn)) or "no characters"
        lines.append(
            "  turn %4d  %10d chars  %s" % (turn["turn"], turn_total(turn), details)
        )
    return "\n".join(lines) + "\n"


def positive_int(text):
    try:
        value = int(text)
    except ValueError:
        value = 0
    if value < 1:
        raise argparse.ArgumentTypeError("must be a positive integer, got %r" % text)
    return value


def fail(message):
    sys.stderr.write("error: %s\n" % message)
    return 2


def main(argv=None):
    if argv is None:
        argv = sys.argv[1:]
    parser = argparse.ArgumentParser(
        prog="context_measure.py",
        description="Measure what fills a session's main-thread context, per turn.",
    )
    parser.add_argument("transcript", help="path to one transcript (JSON Lines) file")
    parser.add_argument(
        "--top", type=positive_int, default=5, help="how many turns to list by size (default 5)"
    )
    parser.add_argument(
        "--json", action="store_true", help="print the full measurement as one JSON object"
    )
    parser.add_argument(
        "--behaviour",
        action="store_true",
        help="add the behaviour baseline (banned phrases, skills, reload checks)",
    )
    args = parser.parse_args(argv)
    path = args.transcript
    if not os.path.isfile(path):
        return fail("not an existing regular file: %s" % ascii_text(path))
    if os.path.getsize(path) == 0:
        return fail("file is empty: %s" % ascii_text(path))
    try:
        records, malformed = load_records(path)
    except OSError as error:
        return fail("cannot read %s: %s" % (ascii_text(path), error.strerror))
    if not records:
        return fail("no parseable JSON object line in %s" % ascii_text(path))
    result = measure(records)
    baseline = behaviour(records) if args.behaviour else None
    if args.json:
        data = {
            "path": path,
            "records": len(records),
            "malformed_lines": malformed,
            "totals": result["totals"],
            "turns": result["turns"],
        }
        if baseline is not None:
            data["behaviour"] = baseline
        sys.stdout.write(json.dumps(data, sort_keys=True, indent=2) + "\n")
    else:
        report = format_report(path, len(records), malformed, result, args.top)
        if baseline is not None:
            report += "\n" + format_behaviour(baseline)
        sys.stdout.write(report)
    return 0


if __name__ == "__main__":
    sys.exit(main())
