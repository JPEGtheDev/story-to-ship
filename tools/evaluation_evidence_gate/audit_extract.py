"""Transcript -> turns extractor for the evaluation-evidence-gate audit runner.

Reads a Claude Code session transcript (one JSON object per line, as written
by the harness) and reduces it to a sequence of "turns": one turn per user
prompt, carrying the final assistant reply text and a coarse turn_type
classification. Sidechain lines (isSidechain: true) and tool-result-only user
lines are not turn boundaries and are excluded or skipped as appropriate.

Usage: python3 audit_extract.py <path-to-transcript.jsonl>
Writes one JSON object per extracted turn to stdout, JSONL-formatted.
"""

import json
import re
import sys

from contracts import TURN_FIELDS, TURN_TYPES

_HAND_OFF_PHRASES = (
    "handing off",
    "over to you",
    "your call",
    "ready for review",
    "your go",
    "let me know",
)

_COMPLETION_CLAIM_PHRASES = (
    "done",
    "complete",
    "fixed",
    "passes",
    "covered",
    "resolved",
    "0 remaining",
    "0 failures",
    "because",
)


def iter_main_thread(lines):
    """Yield only lines whose isSidechain field is False."""
    for line in lines:
        if line.get("isSidechain") is False:
            yield line


def is_turn_delimiter(line):
    """True iff line is a user line whose message content is a real typed
    prompt: a plain string, or an array containing at least one text block.
    A user line whose content array is entirely tool_result blocks is not a
    delimiter."""
    if line.get("type") != "user":
        return False
    content = (line.get("message") or {}).get("content")
    if isinstance(content, str):
        return True
    if isinstance(content, list):
        return any(block.get("type") == "text" for block in content)
    return False


def split_turns(main_thread_lines):
    """Split main-thread lines into turns. A turn is the run of lines after
    one delimiter up to (but not including) the next delimiter, or
    end-of-input. Lines before the first delimiter are ignored."""
    turns = []
    current_turn = None
    for line in main_thread_lines:
        if is_turn_delimiter(line):
            current_turn = []
            turns.append(current_turn)
            continue
        if current_turn is not None:
            current_turn.append(line)
    return turns


def last_text_message(turn_lines):
    """Scan turn_lines for the last assistant message that contains at least
    one text block, and return (line, text): the message line itself and its
    text blocks (in document order, excluding thinking/tool_use blocks)
    joined with "\\n\\n". A text block missing its "text" key contributes ""
    rather than raising. Returns (None, None) if no such assistant message
    exists.

    This is the single source of truth for "find the last assistant text
    message" -- extract_turns and final_text both depend on it so the
    emitted uuid/session/timestamp and the final_text always come from the
    same message by construction."""
    last_line = None
    last_text = None
    for line in turn_lines:
        if line.get("type") != "assistant":
            continue
        content = (line.get("message") or {}).get("content")
        if not isinstance(content, list):
            continue
        text_blocks = [block.get("text", "") for block in content if block.get("type") == "text"]
        if text_blocks:
            last_line = line
            last_text = "\n\n".join(text_blocks)
    return last_line, last_text


def final_text(turn_lines):
    """Thin public wrapper around last_text_message: return just the joined
    text of the last text-bearing assistant message in turn_lines, or None
    if no such assistant message exists."""
    _, text = last_text_message(turn_lines)
    return text


def classify_turn_type(text):
    """Classify text into one of contracts.TURN_TYPES by precedence:
    question > hand_off > completion_claim > other. Cue phrases are matched
    on word boundaries so "incomplete" does not match "complete" and
    "unresolved" does not match "resolved"."""
    non_empty_lines = [ln.strip() for ln in text.splitlines() if ln.strip()]
    if non_empty_lines and non_empty_lines[-1].endswith("?"):
        return "question"

    lowered = text.lower()

    def _matches(phrase):
        return re.search(r"\b" + re.escape(phrase) + r"\b", lowered) is not None

    if any(_matches(phrase) for phrase in _HAND_OFF_PHRASES):
        return "hand_off"
    if any(_matches(phrase) for phrase in _COMPLETION_CLAIM_PHRASES):
        return "completion_claim"
    return "other"


def _read_transcript_lines(path):
    """Read the JSONL transcript at path into a list of dicts. Blank lines,
    undecodable lines, and lines that decode to something other than a JSON
    object are skipped rather than aborting the whole read -- malformed
    transcript data (e.g. a truncated final line) must never crash the
    extractor."""
    lines = []
    with open(path, "r", encoding="utf-8") as f:
        for raw_line in f:
            if not raw_line.strip():
                continue
            try:
                parsed = json.loads(raw_line)
            except json.JSONDecodeError:
                continue
            if not isinstance(parsed, dict):
                continue
            lines.append(parsed)
    return lines


def extract_turns(path):
    """Read the transcript at path and yield one dict per turn (keyed
    exactly by contracts.TURN_FIELDS) for every turn with a non-None
    final_text. Turns with no text-bearing assistant message are skipped."""
    lines = _read_transcript_lines(path)

    main_thread = list(iter_main_thread(lines))
    turns = split_turns(main_thread)

    seq = 0
    for turn_lines in turns:
        source_line, text = last_text_message(turn_lines)
        if text is None:
            continue
        session_id = source_line.get("sessionId")
        yield {
            "turn_id": f"{session_id}#{seq}",
            "source_uuid": source_line.get("uuid"),
            "session_id": session_id,
            "timestamp": source_line.get("timestamp"),
            "turn_type": classify_turn_type(text),
            "final_text": text,
        }
        seq += 1


def main():
    if len(sys.argv) != 2:
        sys.stderr.write("usage: audit_extract.py <path-to-transcript.jsonl>\n")
        return 1
    for turn in extract_turns(sys.argv[1]):
        assert set(turn.keys()) == set(TURN_FIELDS)
        assert turn["turn_type"] in TURN_TYPES
        sys.stdout.write(json.dumps(turn) + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
