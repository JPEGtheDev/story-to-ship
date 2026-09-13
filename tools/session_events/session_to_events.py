"""Convert a Claude Code session transcript (JSON Lines) into an events
JSON Lines file. See README.md for the event schema and conversion rules."""
import argparse
import json
import re
import sys

DEFAULT_MAX_TEXT = 2000
DEFAULT_AGENT_TYPE = "general-purpose"
DEFAULT_MODEL_LABEL = "inherit"
TASK_NOTIFICATION_PREFIX = "<task-notification>"
LAUNCH_ACKNOWLEDGMENT_PREFIX = "Async agent launched successfully"
TOOL_USE_ID_TAG_PATTERN = re.compile(r"<tool-use-id>(.*?)</tool-use-id>", re.DOTALL)


def truncate(text, max_text):
    return text[:max_text]


def extract_tool_use_id_tag(text):
    match = TOOL_USE_ID_TAG_PATTERN.search(text)
    return match.group(1) if match else None


def flatten_tool_result_content(content):
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        text_blocks = [
            block.get("text", "") for block in content if block.get("type") == "text"
        ]
        return "\n".join(text_blocks)
    return ""


def convert_user_string_content(text, ts, max_text):
    if text.startswith(TASK_NOTIFICATION_PREFIX):
        event = {
            "ts": ts,
            "event": "subagent.completed",
            "tool_use_id": extract_tool_use_id_tag(text),
            "text": truncate(text, max_text),
        }
    else:
        event = {"ts": ts, "event": "user.message", "text": truncate(text, max_text)}
    return [event]


def convert_user_list_content(blocks, ts, max_text, agent_tool_use_ids):
    events = []
    for block in blocks:
        if block.get("type") != "tool_result":
            continue
        tool_use_id = block.get("tool_use_id")
        if tool_use_id not in agent_tool_use_ids:
            continue
        flattened_text = flatten_tool_result_content(block.get("content"))
        if flattened_text.startswith(LAUNCH_ACKNOWLEDGMENT_PREFIX):
            continue
        events.append(
            {
                "ts": ts,
                "event": "subagent.completed",
                "tool_use_id": tool_use_id,
                "text": truncate(flattened_text, max_text),
            }
        )
    return events


def convert_user_record(record, max_text, agent_tool_use_ids):
    ts = record.get("timestamp")
    content = record.get("message", {}).get("content")
    if isinstance(content, str):
        return convert_user_string_content(content, ts, max_text)
    if isinstance(content, list):
        return convert_user_list_content(content, ts, max_text, agent_tool_use_ids)
    return []


def convert_tool_use_block(block, ts, agent_tool_use_ids):
    name = block.get("name")
    if name == "Skill":
        skill_name = block.get("input", {}).get("skill")
        return {"ts": ts, "event": "skill.invoked", "skill": skill_name}
    if name == "Agent":
        tool_use_id = block.get("id")
        input_ = block.get("input", {})
        agent_type = input_.get("subagent_type") or DEFAULT_AGENT_TYPE
        model_label = input_.get("model") or DEFAULT_MODEL_LABEL
        agent_tool_use_ids.add(tool_use_id)
        return {
            "ts": ts,
            "event": "subagent.started",
            "tool_use_id": tool_use_id,
            "agent_type": agent_type,
            "model": model_label,
        }
    return None


def convert_assistant_record(record, max_text, agent_tool_use_ids):
    ts = record.get("timestamp")
    model = record.get("message", {}).get("model")
    content = record.get("message", {}).get("content")
    if not isinstance(content, list):
        return []
    events = []
    for block in content:
        block_type = block.get("type")
        if block_type == "text":
            events.append(
                {
                    "ts": ts,
                    "event": "assistant.message",
                    "model": model,
                    "text": truncate(block.get("text", ""), max_text),
                }
            )
        elif block_type == "tool_use":
            event = convert_tool_use_block(block, ts, agent_tool_use_ids)
            if event is not None:
                events.append(event)
    return events


def convert_records(records, max_text=DEFAULT_MAX_TEXT):
    events = []
    agent_tool_use_ids = set()
    for record in records:
        record_type = record.get("type")
        if record_type == "user":
            events.extend(convert_user_record(record, max_text, agent_tool_use_ids))
        elif record_type == "assistant":
            events.extend(
                convert_assistant_record(record, max_text, agent_tool_use_ids)
            )
    return events


def read_records(path):
    records = []
    with open(path, "r", encoding="utf-8") as f:
        for line_number, line in enumerate(f, start=1):
            if not line.strip():
                continue
            try:
                records.append(json.loads(line))
            except json.JSONDecodeError as exc:
                raise ValueError(
                    "Malformed JSON on line {} of {}: {}".format(
                        line_number, path, exc
                    )
                ) from exc
    return records


def build_arg_parser():
    parser = argparse.ArgumentParser(
        description="Convert a Claude Code session transcript to events JSON Lines."
    )
    parser.add_argument("transcript", help="Path to the transcript JSON Lines file.")
    parser.add_argument("--out", help="Path to write events to (default: stdout).")
    parser.add_argument(
        "--max-text",
        type=int,
        default=DEFAULT_MAX_TEXT,
        help="Maximum characters kept per text field (default: {}).".format(
            DEFAULT_MAX_TEXT
        ),
    )
    return parser


def write_events(events, out_path):
    lines = [json.dumps(event) for event in events]
    output_text = "".join(line + "\n" for line in lines)
    if out_path:
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(output_text)
    else:
        sys.stdout.write(output_text)


def main(argv=None):
    args = build_arg_parser().parse_args(argv)
    records = read_records(args.transcript)
    events = convert_records(records, max_text=args.max_text)
    write_events(events, args.out)
    return 0


if __name__ == "__main__":
    sys.exit(main())
