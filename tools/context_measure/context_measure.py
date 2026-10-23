"""Measure what fills a Claude Code session's main-thread context, per turn.

Reads a session transcript (JSON Lines) and reports characters per bucket.
Subagent records (isSidechain true) are excluded. Turn 0 holds everything
before the first human prompt; turn N starts at the Nth human prompt."""
import hashlib
import json
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
    add_chars(turn, "other_harness", string_chars(attachment))


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


def main(argv):
    if len(argv) != 2:
        sys.stderr.write("usage: context_measure.py TRANSCRIPT.jsonl\n")
        return 2
    records, malformed = load_records(argv[1])
    result = measure(records)
    result["malformed_lines"] = malformed
    json.dump(result, sys.stdout, indent=2, sort_keys=True)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
