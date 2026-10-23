"""Measure what fills a Claude Code session's main-thread context, per turn.

Reads a session transcript (JSON Lines) and reports characters per bucket.
Subagent records (isSidechain true) are excluded. Turn 0 holds everything
before the first human prompt; turn N starts at the Nth human prompt."""
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
    tool_names = {}
    seen_blocks = set()
    seen_uuids = set()
    for record in records:
        if not isinstance(record, dict) or record.get("isSidechain") is True:
            continue
        record_type = record.get("type")
        if record_type == "assistant":
            count_assistant(turns[-1], record, tool_names, seen_blocks)
        elif record_type == "user":
            uuid = record.get("uuid")
            if isinstance(uuid, str):
                if uuid in seen_uuids:
                    continue
                seen_uuids.add(uuid)
            if not isinstance(record.get("message"), dict):
                continue
            if is_human_prompt(record):
                turns.append(new_turn(len(turns)))
                count_user_prompt(turns[-1], record)
            else:
                count_tool_results(
                    turns[-1], record["message"].get("content"), tool_names
                )
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
