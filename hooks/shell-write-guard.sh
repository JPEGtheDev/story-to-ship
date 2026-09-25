#!/usr/bin/env bash
# PreToolUse hook (matcher Bash): shell-write-guard.sh
#
# Denies a shell command that would overwrite an existing, git-tracked-or-
# untracked, non-ignored file, because a shell overwrite (a redirect, an
# in-place editor flag, cp/mv/install/rsync onto an existing destination,
# dd of=, or an interpreter snippet opening a path in write mode) bypasses
# the read-before-write guarantee that the Edit and Write tools provide --
# those tools require the file to have been Read first in this session;
# a raw shell write has no such check.
#
# Fail-open list (disclosed, not silent): this hook allows the call
# (exit 0, empty stdout) rather than evaluating it when: jq is not on
# PATH; python3 is not on PATH; stdin is empty; stdin is not valid JSON;
# tool_name is not "Bash"; tool_input.command is empty or missing. Every
# other input is evaluated.
#
# Two rules, keyed on the payload's top-level agent_id (empty for the main
# thread, non-empty inside a dispatched subagent):
#
# Overwrite protection applies to every caller, main thread or subagent
# alike. Unlike bootstrap-gate-pre.sh and workflow-model-guard.sh (both of
# which skip any call carrying a top-level agent_id), this guard does not
# exempt subagents from the overwrite rule -- an implementer's
# `cat > some/tracked/file` is the same defect as the coordinator's own
# session doing it. See hooks/README.md.
#
# For the main thread only (no top-level agent_id), this guard also denies
# writes that create a new file, that append (`>>`, `tee -a`/`--append`,
# an interpreter open() in "a"/"x" mode), or that use an interpreter
# open()/writeFileSync() exclusive-create mode, on any repository path that
# is not gitignored -- so the coordinator's repository changes go through
# the Edit and Write tools, where the inline-edit guard hook counts them.
# A dispatched subagent keeps today's behaviour for these shapes exactly
# (new files, appends, and exclusive-create opens are allowed for it).
#
# No marker and no escape hatch exist. The sanctioned route to overwrite a
# protected file is the Edit or Write tool (Read the file first, then Edit
# or Write it); there is no env var, no inline comment, and no config
# option that lifts this guard for a specific command.
#
# Residual (disclosed, not silent -- see the python scanner below for the
# exhaustive candidate-target rule list): git checkout/restore onto a
# tracked file, formatters invoked with an in-place flag this scanner does
# not recognize, other interpreters, `source`/`bash file.sh` executing a
# script that itself writes, `cp -r` recursing onto a directory of existing
# files, language-level file-write APIs this scanner does not pattern-match
# (e.g. pathlib's Path().write_text in Python), and shell functions/aliases
# that wrap a write are none of them checked -- they fall through as allow.
# If git is not on PATH or a git call times out, the candidate target is
# denied (the guard fails closed on those two errors, unlike the jq/python3
# fail-open cases). A nonzero exit from the repository lookup (git
# rev-parse) means "not a repository" and the write is allowed; once the
# target is known to be inside a repository, only a successful git
# check-ignore match frees it, and any other check-ignore result or error
# leaves it protected.

# Guard against a TTY, and bound the read with timeout, so a manual or
# misbehaving invocation can never hang the hook. Mirrors
# workflow-model-guard.sh.
if [ -t 0 ]; then
  RAW=""
else
  RAW="$(timeout 2 cat 2>/dev/null || true)"
fi

# No jq, no gate: fail open.
command -v jq &>/dev/null || exit 0
[[ -z "$RAW" ]] && exit 0
printf '%s' "$RAW" | jq empty 2>/dev/null || exit 0

TOOL="$(printf '%s' "$RAW" | jq -r '.tool_name // empty' 2>/dev/null)"
[[ "$TOOL" == "Bash" ]] || exit 0

CMD="$(printf '%s' "$RAW" | jq -r '.tool_input.command // empty' 2>/dev/null)"
[[ -z "$CMD" ]] && exit 0

CWD="$(printf '%s' "$RAW" | jq -r '.cwd // empty' 2>/dev/null)"
[[ -z "$CWD" ]] && CWD="$PWD"

# Subagents identify themselves via agent_id; the main-thread-only rules
# below apply only when this is empty.
AGENT_ID="$(printf '%s' "$RAW" | jq -r '.agent_id // empty' 2>/dev/null)"
if [[ -n "$AGENT_ID" ]]; then
  SWG_MAIN_THREAD=0
else
  SWG_MAIN_THREAD=1
fi

# No python3, no scanner: fail open (disclosed above).
command -v python3 &>/dev/null || exit 0

REASON="$(SWG_COMMAND="$CMD" SWG_CWD="$CWD" SWG_MAIN_THREAD="$SWG_MAIN_THREAD" python3 - <<'PY'
import os
import re
import subprocess


class ParseError(Exception):
    """A command could not be tokenized safely."""


class DenyFound(Exception):
    """Short-circuit control flow: a deny verdict was reached."""

    def __init__(self, reason):
        super().__init__(reason)
        self.reason = reason


PREFIX_WORDS = {
    "sudo", "env", "command", "exec", "nohup", "nice", "time", "builtin",
}

NESTED_SHELLS = {"bash", "sh", "zsh", "dash", "ksh"}
INTERPRETERS = {"python", "python2", "python3", "node", "nodejs"}

# Longest-match-first redirect operator table. Each entry maps the operator
# text to whether it is a *candidate* write redirect (per rule C) and
# whether it consumes a following target word at all (heredocs and
# here-strings do not target a file the way > family operators do, but the
# tokenizer still needs to know how many following tokens to treat as
# operator-adjacent).
REDIRECT_OPS = [
    "<<<", "<<-", "&>>",
    "<<", ">>", ">|", "<>", "&>", ">&", "<(", ">(",
    ">", "<",
]

# Characters that terminate a bare (unquoted) heredoc delimiter word. Shared
# by parse_heredoc_delimiter so the top-level tokenizer and the nested
# paren/backtick span-matchers agree on exactly one word-terminator set.
HEREDOC_DELIM_TERMINATORS = " \t\n<>;&|()"


def parse_heredoc_delimiter(s, i):
    """s[i] is the position immediately after a matched '<<'/'<<-'
    operator. Skips leading spaces/tabs, then reads the heredoc delimiter
    word (quote-stripped if quoted; the quoted/unquoted distinction only
    affects expansion inside the body, which this scanner never expands
    anyway). Returns (delim_text, index_after_delim)."""
    n = len(s)
    while i < n and s[i] in (" ", "\t"):
        i += 1
    if i < n and s[i] == "'":
        j = s.find("'", i + 1)
        if j == -1:
            raise ParseError("unterminated single quote")
        return s[i + 1:j], j + 1
    if i < n and s[i] == '"':
        j = s.find('"', i + 1)
        if j == -1:
            raise ParseError("unterminated double quote")
        return s[i + 1:j], j + 1
    j = i
    while j < n and s[j] not in HEREDOC_DELIM_TERMINATORS:
        j += 1
    return s[i:j], j


def consume_heredoc_body(s, i, delim, strip_tabs, collect):
    """s[i] is the position right after the newline that starts heredoc
    body consumption. Reads lines until one equals delim (after stripping
    leading tabs if strip_tabs), raising ParseError("unterminated heredoc")
    if the delimiter is never found before the end of the text. Returns
    (index_after_delim_line, body_or_None) -- body is the consumed lines
    joined with a trailing newline when collect is True (the shape
    tokenize_and_scan stores on segment.heredoc_bodies for the interpreter
    rule), or None when collect is False (find_matching_paren and
    find_matching_backtick only need to skip past the body to keep their
    own quote/paren-depth tracking correct, not its text)."""
    n = len(s)
    body_lines = [] if collect else None
    while i <= n:
        nl = s.find("\n", i)
        line_end = nl if nl != -1 else n
        line = s[i:line_end]
        cmp_line = line.lstrip("\t") if strip_tabs else line
        if cmp_line == delim:
            i = line_end + 1 if nl != -1 else n
            if collect:
                return i, "\n".join(body_lines) + ("\n" if body_lines else "")
            return i, None
        if collect:
            body_lines.append(line)
        if nl == -1:
            raise ParseError("unterminated heredoc")
        i = nl + 1
    raise ParseError("unterminated heredoc")


def _scan_nested_span(s, open_idx, closer):
    """Shared quote- and heredoc-aware walk used by find_matching_paren
    (closer is a depth-counted ')') and find_matching_backtick (closer is
    an unescaped '`', which does not nest via depth -- a literal nested
    backtick must itself be backslash-escaped in real bash). Returns
    (inner_text, index_after_close)."""
    n = len(s)
    i = open_idx + 1
    start = i
    state = "normal"
    pending_heredocs = []
    depth = 1
    while i < n:
        c = s[i]
        if state == "squote":
            if c == "'":
                state = "normal"
            i += 1
            continue
        if state == "dquote":
            if c == "\\":
                i += 2
                continue
            if c == '"':
                state = "normal"
            i += 1
            continue

        # state == "normal"
        if c == "\n":
            if pending_heredocs:
                i += 1
                for delim, strip_tabs in pending_heredocs:
                    i, _ = consume_heredoc_body(s, i, delim, strip_tabs, False)
                pending_heredocs = []
                continue
            i += 1
            continue
        if c == "\\":
            i += 2
            continue
        if c == "'":
            state = "squote"
            i += 1
            continue
        if c == '"':
            state = "dquote"
            i += 1
            continue
        if closer == ")":
            if c == "(":
                depth += 1
                i += 1
                continue
            if c == ")":
                depth -= 1
                if depth == 0:
                    return s[start:i], i + 1
                i += 1
                continue
        elif c == "`":
            return s[start:i], i + 1
        if s[i:i + 3] == "<<<":
            i += 3
            continue
        if s[i:i + 3] == "<<-" or s[i:i + 2] == "<<":
            strip_tabs = s[i:i + 3] == "<<-"
            i += 3 if strip_tabs else 2
            delim, i = parse_heredoc_delimiter(s, i)
            pending_heredocs.append((delim, strip_tabs))
            continue
        i += 1
    if pending_heredocs:
        raise ParseError("unterminated heredoc")
    if state == "squote":
        raise ParseError("unterminated single quote")
    if state == "dquote":
        raise ParseError("unterminated double quote")
    raise ParseError("unterminated parenthesis" if closer == ")" else "unterminated backtick")


def find_matching_paren(s, open_idx):
    """s[open_idx] == '('. Return (inner_text, index_after_close).

    Quote-aware AND heredoc-aware: a `<<`/`<<-` inside the span queues a
    heredoc whose body (consumed at the next unescaped newline, exactly as
    at top level) is skipped without letting its content perturb the
    quote-depth tracking used to find the matching close paren.
    """
    return _scan_nested_span(s, open_idx, ")")


def find_matching_backtick(s, open_idx):
    """s[open_idx] == '`'. Return (inner_text, index_after_close).

    Quote-aware and heredoc-aware, mirroring find_matching_paren, but
    delimited by an unescaped closing backtick rather than paren depth --
    bash backtick substitution does not nest via bare backticks.
    """
    return _scan_nested_span(s, open_idx, "`")


def match_redirect(s, i):
    """Try to match a redirect operator at position i (not inside quotes).

    Returns (op_text, end_index, digit_prefix) or None. digit_prefix is the
    leading fd-number text ("" if none).
    """
    n = len(s)
    j = i
    while j < n and s[j].isdigit():
        j += 1
    digit_prefix = s[i:j]
    rest = s[j:]

    if rest.startswith(">") and i > 0 and s[i - 1] == "-" and not digit_prefix:
        # the `->` arrow case: not a redirect.
        return None

    # fd-dup / fd-close forms consume the whole thing, never a candidate.
    m = re.match(r'^>&(\d+|-)', rest)
    if m:
        return (digit_prefix + m.group(0), j + m.end(), digit_prefix)

    for op in REDIRECT_OPS:
        if rest.startswith(op):
            if op in ("<", "<(", "<<", "<<-", "<<<", "<>") and not digit_prefix:
                return (op, j + len(op), digit_prefix)
            if op in ("<", "<(", "<<", "<<-", "<<<", "<>") and digit_prefix:
                return (digit_prefix + op, j + len(op), digit_prefix)
            if op == ">" and i > 0 and s[i - 1] == "-" and not digit_prefix:
                continue
            return (digit_prefix + op, j + len(op), digit_prefix)
    return None


class Token(object):
    __slots__ = ("text", "literal")

    def __init__(self, text="", literal=True):
        self.text = text
        self.literal = literal


class Segment(object):
    def __init__(self):
        self.tokens = []          # list of ("word", Token) or ("op", str)
        self.heredoc_bodies = []


def tokenize_and_scan(text, base, top_cwd):
    """Recursive-descent scan of one chunk of shell text.

    Returns None (allow) or raises DenyFound with the first denial found,
    scanning in segment (i.e. left-to-right, top-to-bottom) order. Also
    may raise ParseError for an unterminated construct.
    """
    n = len(text)
    i = 0
    segments = []
    seg = Segment()
    cur = None  # current Token being built, or None
    pending_heredocs = []  # list of (delim_text, strip_tabs)

    def flush_word():
        nonlocal cur
        if cur is not None:
            seg.tokens.append(("word", cur))
            cur = None

    def start_word():
        nonlocal cur
        if cur is None:
            cur = Token("", True)
        return cur

    def finalize_segment():
        nonlocal seg
        flush_word()
        if seg.tokens:
            segments.append(seg)
        seg = Segment()

    while i < n:
        c = text[i]

        if c == "\\":
            # Backslash-escape: consumes the next character literally.
            if i + 1 >= n:
                start_word()
                i += 1
                continue
            nxt = text[i + 1]
            start_word().text += nxt
            i += 2
            continue

        if c == "'":
            start_word()
            j = text.find("'", i + 1)
            if j == -1:
                raise ParseError("unterminated single quote")
            cur.text += text[i + 1:j]
            i = j + 1
            continue

        if c == '"':
            start_word()
            j = i + 1
            buf = []
            closed = False
            while j < n:
                cj = text[j]
                if cj == "\\" and j + 1 < n and text[j + 1] in ('"', "\\", "$", "`", "\n"):
                    buf.append(text[j + 1])
                    j += 2
                    continue
                if cj == "$" and j + 1 < n and text[j + 1] == "(":
                    # $( ) inside a double-quoted string: bash resets
                    # quoting context to normal for the substitution's own
                    # span, so it must be located with the same quote- and
                    # heredoc-aware matcher used outside quotes, and its
                    # contents recursively scanned for a hidden write --
                    # not just copied through as opaque text.
                    cur.literal = False
                    inner, end2 = find_matching_paren(text, j + 1)
                    tokenize_and_scan(inner, base, top_cwd)
                    buf.append(text[j:end2])
                    j = end2
                    continue
                if cj == "`":
                    # Backtick substitution inside a double-quoted string:
                    # same recursion as $( ), delimited by an unescaped
                    # backtick instead of a matching close paren.
                    cur.literal = False
                    inner, end2 = find_matching_backtick(text, j)
                    tokenize_and_scan(inner, base, top_cwd)
                    buf.append(text[j:end2])
                    j = end2
                    continue
                if cj == '"':
                    closed = True
                    j += 1
                    break
                if cj == "$":
                    cur.literal = False
                buf.append(cj)
                j += 1
            if not closed:
                raise ParseError("unterminated double quote")
            cur.text += "".join(buf)
            i = j
            continue

        if c in (" ", "\t"):
            flush_word()
            i += 1
            continue

        if c == "\n":
            if pending_heredocs:
                i += 1
                for delim, strip_tabs in pending_heredocs:
                    i, body = consume_heredoc_body(text, i, delim, strip_tabs, True)
                    seg.heredoc_bodies.append(body)
                pending_heredocs = []
                continue
            flush_word()
            finalize_segment()
            i += 1
            continue

        if c == ";":
            flush_word()
            finalize_segment()
            i += 1
            continue

        if c == "&":
            if text[i:i + 2] == "&&":
                flush_word()
                finalize_segment()
                i += 2
                continue
            # bare & (background) -- but not when it is part of a redirect
            # operator (those are handled by match_redirect before we get
            # here via the '>' / '<' / digit branches below). A raw '&'
            # reaching this point is a background/separator token.
            flush_word()
            finalize_segment()
            i += 1
            continue

        if c == "|":
            if text[i:i + 2] == "|&":
                flush_word()
                finalize_segment()
                i += 2
                continue
            if text[i:i + 2] == "||":
                flush_word()
                finalize_segment()
                i += 2
                continue
            flush_word()
            finalize_segment()
            i += 1
            continue

        if c == "$" and i + 1 < n and text[i + 1] == "(":
            start_word()
            cur.literal = False
            inner, end = find_matching_paren(text, i + 1)
            tokenize_and_scan(inner, base, top_cwd)
            cur.text += text[i:end]
            i = end
            continue

        if c == "(":
            # Bare subshell grouping. Finish whatever segment/word precedes
            # it (rare to have one; usually parens open at segment start),
            # recursively scan the inner text with the *current* base
            # (push), and do not let anything inside leak back out (pop is
            # implicit: Python's call-by-value on the base string/None).
            flush_word()
            finalize_segment()
            inner, end = find_matching_paren(text, i)
            tokenize_and_scan(inner, base, top_cwd)
            i = end
            continue

        if c == ")":
            # An unmatched ')' at top level (never reachable from inside a
            # find_matching_paren-extracted span, since that extraction
            # stops before its own closing paren) is legal bash only as a
            # case-pattern terminator (e.g. `1) echo a ;;`), so treat it as
            # a plain segment separator rather than a parse error. An
            # unmatched '(' is still a genuine parse error (no legal bash
            # construct opens a paren with no matching close at top level).
            flush_word()
            finalize_segment()
            i += 1
            continue

        if c == "`":
            # Bare (unquoted) backtick substitution: same recursion as the
            # $( ) case just above, delimited by an unescaped backtick.
            start_word()
            cur.literal = False
            inner, end = find_matching_backtick(text, i)
            tokenize_and_scan(inner, base, top_cwd)
            cur.text += text[i:end]
            i = end
            continue

        if c in (">", "<") or c.isdigit():
            m = match_redirect(text, i)
            if m is not None:
                op_text, end, digit_prefix = m
                flush_word()
                op_base = op_text.lstrip("0123456789")
                if op_base in ("<(", ">("):
                    # process substitution: skip as a nested segment group,
                    # never a file target.
                    inner, pend = find_matching_paren(text, end - 1)
                    tokenize_and_scan(inner, base, top_cwd)
                    i = pend
                    continue
                if op_base in ("<<", "<<-"):
                    strip_tabs = op_base == "<<-"
                    i = end
                    delim, i = parse_heredoc_delimiter(text, i)
                    pending_heredocs.append((delim, strip_tabs))
                    seg.tokens.append(("op", op_text))
                    continue
                seg.tokens.append(("op", op_text))
                i = end
                continue
            # digit not forming a redirect: ordinary word character.
            start_word()
            cur.text += c
            i += 1
            continue

        if c in ("*", "?", "["):
            start_word()
            cur.literal = False
            cur.text += c
            i += 1
            continue

        start_word()
        cur.text += c
        i += 1

    if pending_heredocs:
        raise ParseError("unterminated heredoc")
    finalize_segment()

    for segment in segments:
        base = process_segment(segment, base, top_cwd)
    return None


def leading_command_word(tokens):
    """Return (index_of_command_word, is_cd_like) skipping VAR=x assigns
    and known prefix words / timeout <duration>."""
    idx = 0
    n = len(tokens)
    while idx < n:
        kind, tok = tokens[idx]
        if kind != "word":
            return None
        if tok.literal and re.match(r'^[A-Za-z_][A-Za-z0-9_]*=', tok.text):
            idx += 1
            continue
        break
    if idx >= n:
        return None
    kind, tok = tokens[idx]
    if kind != "word":
        return None
    word = tok.text
    if word == "timeout":
        idx += 1
        # skip the duration argument, if present
        if idx < n and tokens[idx][0] == "word":
            idx += 1
        if idx < n and tokens[idx][0] == "word":
            return idx
        return None
    if word in PREFIX_WORDS:
        idx += 1
        while idx < n and tokens[idx][0] == "word" and tokens[idx][1].literal and \
                re.match(r'^[A-Za-z_][A-Za-z0-9_]*=', tokens[idx][1].text):
            idx += 1
        if idx < n and tokens[idx][0] == "word":
            return idx
        return None
    return idx


def expand_home(p):
    if p == "~" or p.startswith("~/"):
        home = os.environ.get("HOME", "")
        return home + p[1:]
    return p


# Read once into a module-level constant: SWG_MAIN_THREAD="1" means the hook
# payload carried no top-level agent_id (a main-thread call); "0" (or
# anything else) means a dispatched subagent. See the header comment above
# for the two rules this flag switches between.
MAIN_THREAD = os.environ.get("SWG_MAIN_THREAD", "0") == "1"


def nearest_existing_dir(path):
    """Walk up from path until an existing directory is found, so a
    repository lookup for a target under a not-yet-created directory (e.g.
    newdir/x.md) still runs from a real ancestor instead of failing on a
    missing cwd."""
    d = path
    while d and not os.path.isdir(d):
        parent = os.path.dirname(d)
        if parent == d:
            return d
        d = parent
    return d


def overwrite_reason(realpath, mechanism):
    """The deny reason for a candidate target inside a non-ignored
    repository. Main-thread calls get one unified reason (used for
    overwrite, new-file, append, and the git-error fail-closed path);
    subagent calls keep today's overwrite reason unchanged."""
    if MAIN_THREAD:
        return (
            "shell-write-guard: main-thread shell writes to repository "
            "files are not allowed (%s, mechanism: %s). Use the Edit or "
            "Write tool (the inline-edit guard counts those edits) or "
            "dispatch an implementer." % (realpath, mechanism)
        )
    return (
        "shell-write-guard: this command would overwrite the existing repo "
        "file %s (mechanism: %s). Read it with the Read tool and change it "
        "with the Edit or Write tool; use >> if you meant to append."
        % (realpath, mechanism)
    )


def check_candidate(raw_token, mechanism, base, top_cwd):
    """raw_token: Token. Denies via DenyFound, or returns (allow)."""
    if not raw_token.literal:
        text = raw_token.text
        if text.startswith("/tmp/") or text.startswith("/dev/"):
            return
        raise DenyFound(
            "shell-write-guard: the write target %s is not a literal path "
            "(a variable, command substitution, or glob), so it cannot be "
            "checked -- target must be a literal path; write to a literal "
            "path under /tmp or use the Write tool." % text
        )

    text = raw_token.text
    if text.startswith("/dev/"):
        return

    if base is None and not text.startswith("/"):
        raise ParseError("unresolvable working directory after cd")
    if base is not None and not os.path.isabs(base):
        raise ParseError("unresolvable working directory")

    expanded = expand_home(text)
    if os.path.isabs(expanded):
        path = os.path.normpath(expanded)
    else:
        path = os.path.normpath(os.path.join(base, expanded))

    realpath = os.path.realpath(path)
    if not os.path.isfile(realpath) and not MAIN_THREAD:
        return

    lookup_dir = nearest_existing_dir(os.path.dirname(realpath))
    try:
        top = subprocess.run(
            ["git", "-C", lookup_dir, "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=2,
        )
    except Exception:
        raise DenyFound(overwrite_reason(realpath, mechanism))
    if top.returncode != 0:
        return

    top_dir = top.stdout.strip()
    try:
        ignore = subprocess.run(
            ["git", "-C", top_dir, "check-ignore", "-q", "--", realpath],
            capture_output=True, text=True, timeout=2,
        )
    except Exception:
        ignore = None

    if ignore is not None and ignore.returncode == 0:
        return

    raise DenyFound(overwrite_reason(realpath, mechanism))


def is_flag(tok):
    return tok.literal and tok.text.startswith("-") and tok.text != "-"


def words_only(tokens):
    return [tok for kind, tok in tokens if kind == "word"]


def check_tee(args, base, top_cwd):
    append = any(a.literal and a.text in ("-a", "--append") for a in args)
    if append and not MAIN_THREAD:
        return
    for a in args:
        if is_flag(a):
            continue
        check_candidate(a, "tee", base, top_cwd)


def check_sed(args, base, top_cwd):
    inplace = False
    has_e_or_f = False
    for a in args:
        if not a.literal:
            continue
        t = a.text
        if t in ("-i", "--in-place") or t.startswith("--in-place="):
            inplace = True
        elif re.match(r'^-[A-Za-z]*i', t) and t not in ("-e", "-f"):
            inplace = True
        if t in ("-e", "--expression", "-f", "--file"):
            has_e_or_f = True
    if not inplace:
        return
    non_flags = []
    skip_next = False
    for a in args:
        if skip_next:
            skip_next = False
            continue
        if is_flag(a):
            if a.literal and a.text in ("-e", "--expression", "-f", "--file"):
                skip_next = True
            continue
        non_flags.append(a)
    if not has_e_or_f and non_flags:
        non_flags = non_flags[1:]
    for a in non_flags:
        check_candidate(a, "sed -i", base, top_cwd)


def check_perl_ruby(cmd_word, args, base, top_cwd):
    inplace = any(a.literal and re.match(r'^-[A-Za-z]*i', a.text) for a in args)
    if not inplace:
        return
    skip_next = False
    for a in args:
        if skip_next:
            skip_next = False
            continue
        if is_flag(a):
            if a.literal and a.text in ("-e", "-E"):
                skip_next = True
            continue
        check_candidate(a, "%s -i" % cmd_word, base, top_cwd)


def check_cp_family(cmd_word, args, base, top_cwd):
    force = any(
        a.literal and (a.text in ("-f", "-sf", "-fs", "--force") or
                        (a.text.startswith("-") and not a.text.startswith("--") and "f" in a.text[1:]))
        for a in args
    )
    active = force if cmd_word == "ln" else True
    if not active:
        return

    target_dir = None
    non_flags = []
    k = 0
    while k < len(args):
        a = args[k]
        if a.literal and a.text == "--":
            k += 1
            non_flags.extend(args[k:])
            break
        if a.literal and (a.text == "-t" or a.text.startswith("--target-directory=")):
            if a.text == "-t" and k + 1 < len(args):
                target_dir = args[k + 1].text if args[k + 1].literal else None
                k += 2
                continue
            elif a.text.startswith("--target-directory="):
                target_dir = a.text.split("=", 1)[1]
                k += 1
                continue
        if is_flag(a):
            k += 1
            continue
        non_flags.append(a)
        k += 1

    if target_dir is not None:
        for src in non_flags:
            if not src.literal:
                check_candidate(src, cmd_word, base, top_cwd)
                continue
            dest_text = target_dir.rstrip("/") + "/" + os.path.basename(src.text)
            check_candidate(Token(dest_text, True), cmd_word, base, top_cwd)
        return

    if not non_flags or (cmd_word == "ln" and not force):
        return

    dest = non_flags[-1]
    sources = non_flags[:-1]
    if not dest.literal:
        if sources:
            check_candidate(dest, cmd_word, base, top_cwd)
        return

    dest_path = dest.text
    if not os.path.isabs(expand_home(dest_path)):
        resolved_base = base if base else top_cwd
        dest_abs = os.path.normpath(os.path.join(resolved_base, expand_home(dest_path)))
    else:
        dest_abs = os.path.normpath(expand_home(dest_path))
    is_dir = os.path.isdir(os.path.realpath(dest_abs))
    if is_dir and sources:
        for src in sources:
            if not src.literal:
                check_candidate(src, cmd_word, base, top_cwd)
                continue
            dest_text = dest_path.rstrip("/") + "/" + os.path.basename(src.text)
            check_candidate(Token(dest_text, True), cmd_word, base, top_cwd)
    elif sources:
        check_candidate(dest, cmd_word, base, top_cwd)


def check_dd(args, base, top_cwd):
    for a in args:
        if a.literal:
            m = re.match(r'^of=(.+)$', a.text)
            if m:
                check_candidate(Token(m.group(1), True), "dd", base, top_cwd)
        else:
            if a.text.startswith("of="):
                check_candidate(Token(a.text[3:], False), "dd", base, top_cwd)


def check_truncate(args, base, top_cwd):
    skip_next = False
    for a in args:
        if skip_next:
            skip_next = False
            continue
        if is_flag(a):
            if a.literal and a.text in ("-s", "--size"):
                skip_next = True
            continue
        check_candidate(a, "truncate", base, top_cwd)


def check_interpreter(cmd_word, args, segment, base, top_cwd):
    # python/python2/python3 take inline code via -c; node/nodejs have no
    # -c flag and instead take it via -e/--eval or -p/--print.
    inline_flags = ("-c",) if cmd_word.startswith("python") else \
        ("-e", "--eval", "-p", "--print")
    inspect_text = []
    skip_next = False
    for a in args:
        if skip_next:
            inspect_text.append(a.text)
            skip_next = False
            continue
        if a.literal and a.text in inline_flags:
            skip_next = True
            continue
    for body in segment.heredoc_bodies:
        inspect_text.append(body)
    joined = "\n".join(inspect_text)
    if joined:
        scan_interpreter_snippet(joined, base, top_cwd)


def check_nested_shells(tokens, base, top_cwd):
    i = 0
    n = len(tokens)
    while i < n:
        kind, tok = tokens[i]
        if kind == "word" and tok.literal and tok.text in NESTED_SHELLS:
            if (i + 1 < n and tokens[i + 1][0] == "word" and
                    tokens[i + 1][1].literal and tokens[i + 1][1].text == "-c" and
                    i + 2 < n and tokens[i + 2][0] == "word"):
                nested_text = tokens[i + 2][1].text
                tokenize_and_scan(nested_text, base, top_cwd)
        if kind == "word" and tok.literal and tok.text == "eval":
            rest_words = [t.text for t in words_only(tokens[i + 1:])]
            if rest_words:
                tokenize_and_scan(" ".join(rest_words), base, top_cwd)
        i += 1


def process_segment(segment, base, top_cwd):
    tokens = segment.tokens

    cmd_idx = leading_command_word(tokens)
    cmd_word = None
    if cmd_idx is not None:
        kind, tok = tokens[cmd_idx]
        cmd_word = tok.text if tok.literal else None

    # --- cd / pushd / popd base tracking -----------------------------
    if cmd_word in ("cd", "pushd", "popd"):
        args = words_only(tokens[cmd_idx + 1:])
        if cmd_word == "popd":
            return None
        if not args or args[0].text == "~":
            return os.environ.get("HOME", "") or None
        arg = args[0]
        if arg.text == "-" or not arg.literal:
            return None
        if base is None:
            raise ParseError("unresolvable working directory after cd")
        return os.path.normpath(os.path.join(base, expand_home(arg.text)))

    # --- redirect candidates (checked on every segment, regardless of
    # command word) --------------------------------------------------
    i = 0
    n = len(tokens)
    while i < n:
        kind, val = tokens[i]
        if kind == "op":
            base_op = val.lstrip("0123456789")
            is_write_redirect = base_op in (">", ">|", "&>") or \
                (MAIN_THREAD and base_op == ">>")
            if is_write_redirect and i + 1 < n and tokens[i + 1][0] == "word":
                target = tokens[i + 1][1]
                check_candidate(target, "redirect", base, top_cwd)
        i += 1

    # --- mechanism-specific candidates: each branch is a dispatch to its
    # own check_<mechanism>() function; process_segment itself is just the
    # dispatch skeleton. -------------------------------------------------
    if cmd_word == "tee":
        check_tee(words_only(tokens[cmd_idx + 1:]), base, top_cwd)
    elif cmd_word == "sed":
        check_sed(words_only(tokens[cmd_idx + 1:]), base, top_cwd)
    elif cmd_word in ("perl", "ruby"):
        check_perl_ruby(cmd_word, words_only(tokens[cmd_idx + 1:]), base, top_cwd)
    elif cmd_word in ("cp", "mv", "install", "rsync", "ln"):
        check_cp_family(cmd_word, words_only(tokens[cmd_idx + 1:]), base, top_cwd)
    elif cmd_word == "dd":
        check_dd(words_only(tokens[cmd_idx + 1:]), base, top_cwd)
    elif cmd_word == "truncate":
        check_truncate(words_only(tokens[cmd_idx + 1:]), base, top_cwd)
    elif cmd_word in INTERPRETERS:
        check_interpreter(cmd_word, words_only(tokens[cmd_idx + 1:]), segment, base, top_cwd)

    # --- nested shells and eval -----------------------------------------
    check_nested_shells(tokens, base, top_cwd)

    return base


# Write-mode chars matched in an interpreter open() call: "w" for every
# caller; main-thread calls additionally count "a" (append) and "x"
# (exclusive create) as write modes, since those are also the main-thread
# write shapes this guard denies on repository paths.
_WRITE_MODE_CHARS = "wax" if MAIN_THREAD else "w"
WRITE_MODE_LITERAL_RE = re.compile(
    r'open\(\s*([\'"])(?P<path>[^\'"]*)\1\s*,\s*(mode\s*=\s*)?([\'"])[%s][^\'"]*\4'
    % _WRITE_MODE_CHARS
)
WRITE_MODE_NONLITERAL_RE = re.compile(
    r'open\(\s*(?P<expr>[^\'"\s,)][^,)]*)\s*,\s*(mode\s*=\s*)?([\'"])[%s]'
    % _WRITE_MODE_CHARS
)
WRITEFILESYNC_RE = re.compile(
    r'writeFileSync\(\s*([\'"])(?P<path>[^\'"]*)\1'
)


IDENT_RE = re.compile(r'^[A-Za-z_][A-Za-z0-9_]*$')


def resolve_interpreter_target(expr, preceding_text):
    """Resolve a non-literal open()/writeFileSync() target expression.

    Returns ('literal', text) if a preceding plain-string assignment
    resolves a bare identifier, ('allow', None) if an f-string/plain
    string's literal prefix (before the first { or the whole string) is
    under /tmp/ or /dev/, or ('nonliteral', raw_text) otherwise.
    """
    if IDENT_RE.match(expr):
        # Last single-line, plain-string (no f/r/b prefix) assignment to
        # this identifier before the open( call wins -- most recent
        # assignment reflects what the interpreter would actually see.
        assign_re = re.compile(
            r'(?<![A-Za-z0-9_])' + re.escape(expr) +
            r'\s*=\s*([\'"])((?:(?!\1)[^\n])*)\1(?!\s*[\'"])'
        )
        last = None
        for m in assign_re.finditer(preceding_text):
            # Reject an f/r/b-prefixed literal immediately before the
            # matched quote (e.g. `p = f'...'` must not resolve as plain).
            start = m.start(1)
            if start > 0 and preceding_text[start - 1] in "fFrRbB":
                continue
            last = m
        if last is not None:
            return ("literal", last.group(2))
        return ("nonliteral", expr)

    m = re.match(r'^[fF]([\'"])(.*)$', expr, re.DOTALL)
    if m:
        quote = m.group(1)
        body = m.group(2)
        brace_idx = body.find("{")
        prefix = body[:brace_idx] if brace_idx != -1 else body.rstrip(quote)
        if prefix.startswith("/tmp/") or prefix.startswith("/dev/"):
            return ("allow", None)
        return ("nonliteral", expr)

    return ("nonliteral", expr)


def scan_interpreter_snippet(text, base, top_cwd):
    for m in WRITE_MODE_LITERAL_RE.finditer(text):
        check_candidate(Token(m.group("path"), True), "interpreter open()", base, top_cwd)
    for m in WRITE_MODE_NONLITERAL_RE.finditer(text):
        expr = m.group("expr")
        if re.match(r'^[\'"]', expr):
            continue
        kind, val = resolve_interpreter_target(expr, text[:m.start()])
        if kind == "literal":
            check_candidate(Token(val, True), "interpreter open()", base, top_cwd)
        elif kind == "allow":
            continue
        else:
            check_candidate(Token(expr, False), "interpreter open()", base, top_cwd)
    for m in WRITEFILESYNC_RE.finditer(text):
        check_candidate(Token(m.group("path"), True), "writeFileSync()", base, top_cwd)


def main():
    command = os.environ.get("SWG_COMMAND", "")
    cwd = os.environ.get("SWG_CWD", "")
    if not os.path.isabs(cwd):
        print("shell-write-guard: could not parse the command safely "
              "(unresolvable working directory); simplify the command or "
              "use the Write tool.")
        return
    try:
        tokenize_and_scan(command, cwd, cwd)
    except DenyFound as exc:
        print(exc.reason)
    except ParseError as exc:
        print("shell-write-guard: could not parse the command safely (%s); "
              "simplify the command or use the Write tool." % str(exc))
    except Exception as exc:  # noqa: BLE001 - deny on any scanner defect
        print("shell-write-guard: scanner error (%s: %s); simplify the "
              "command or use the Write tool." % (type(exc).__name__, exc))


main()
PY
)"

[[ -z "$REASON" ]] && exit 0

jq -cn \
  --arg reason "$REASON" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse", permissionDecision:"deny", permissionDecisionReason:$reason}}'

exit 0
