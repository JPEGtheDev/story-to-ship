# Hooks

Hook scripts and the text they inject into Claude Code sessions. This README documents the directory; it is never injected.

`session-start.sh` inspects the SessionStart `source` on stdin and, on `compact`/`resume`, prepends a continuation re-grounding banner before its paired `session-start.md`.

## Files

| File | Event | Injected |
|------|-------|----------|
| `session-start.sh` + `session-start.md` | SessionStart | On every SessionStart event, whatever its source |
| `pre-message-gates.sh` + `pre-message-gates.md` | UserPromptSubmit | On turns where the bootstrap flag exists, or its state cannot be read |
| `pre-message-gates.sh` + `pre-message-gates-loaded.md` | UserPromptSubmit | On turns where the bootstrap flag is clear |
| `pre-message.sh` + `pre-message.md` | UserPromptSubmit | On turns where the honesty or communication flag exists, or their state cannot be read |
| `pre-message.sh` + `pre-message-loaded.md` | UserPromptSubmit | On turns where both the honesty and communication flags are clear |
| `stop-turn-log.sh` | Stop | Never -- passive log, no injection |
| `bootstrap-gate-pre.sh` | PreToolUse | No context injection in deny mode (shipped default) -- it denies the call instead; in warn fallback, a nudge only when the session is un-bootstrapped |
| `bootstrap-gate-post.sh` | PostToolUse | Never -- clears state, no injection |
| `workflow-model-guard.sh` | PreToolUse (matcher `Workflow`) | Only when a Workflow script has an unpinned `agent(` call, and only as a deny reason -- never as injected context |
| `shell-write-guard.sh` | PreToolUse (matcher `Bash`) | Only when a shell command would overwrite an existing repo file, or, from the main session, create or append to a repo file that is not gitignored; and only as a deny reason -- never as injected context |
| `inline-edit-guard.sh` | PreToolUse (matcher `Edit\|Write`) | Only when a main-session Edit or Write would change a file that is not prose or pass a changed-line cap, and only as a deny reason -- never as injected context |

Each text-injecting `.sh` script wraps its paired `.md` file in the hook JSON envelope (`additionalContext`), except the bootstrap-gate pair, `workflow-model-guard.sh`, `shell-write-guard.sh`, and `inline-edit-guard.sh`, whose deny/warn text is generated inline by the scripts themselves. `pre-message-gates.sh` and `pre-message.sh` each have two paired files -- the full file and a `-loaded` variant -- and inject exactly one of them per turn, chosen by the pending flags described in the bootstrap-gate section below. Six `.sh` files have no paired `.md` file: `bootstrap-gate-pre.sh`, `bootstrap-gate-post.sh`, `workflow-model-guard.sh`, `shell-write-guard.sh`, and `inline-edit-guard.sh` (inline-generated text, as above), plus `stop-turn-log.sh` -- which is not a text-injecting script at all, but a passive logger that injects nothing (see its own section below). Registration lives in `hooks.json` (plugin path) and `.claude/settings.json` (this repo's own checkout).

## Provenance of the injected text

The per-turn files are tripwires, not rule bodies:

- `pre-message-gates.md` derives from the `session-bootstrap` skill. Its Bootstrap Gate section checks for a completed `Skill(session-bootstrap)` call and is injected only while the bootstrap flag exists. Its reload-trigger and skill-routing sections are injected on every turn -- alone, as `pre-message-gates-loaded.md`, once the flag is clear.
- `pre-message.md` derives from the `honesty` and `communication` skills. Its Honesty Gate section checks for completed `Skill(honesty)` and `Skill(communication)` calls and is injected only while the honesty or communication flag exists. Its banned-vocabulary and before-sending sections are injected on every turn -- alone, as `pre-message-loaded.md`, once both flags are clear.

The full rules live in `skills/session-bootstrap/SKILL.md`, `skills/honesty/SKILL.md`, and `skills/communication/SKILL.md`. Hook text reminds; only a `Skill` tool call loads the rules. When a skill changes, update the derived hook text to match -- the hook must never contradict its source skill.

## Word budget

One file from each per-turn pair is injected on every user prompt, so their size is a recurring token cost. CI (`.github/workflows/validate.yml`) enforces a combined budget of 495 words for `pre-message-gates.md` + `pre-message.md`: the full pair is the worst-case turn, injected while the pending flags exist. CI also requires each `-loaded` variant to have fewer words than its full file, and to match its full file with the gate section removed, so changing a shared section in one file but not the other fails CI. `session-start.md` fires on each SessionStart event, not per turn, and is outside the budget.

## Mirror in .claude/hooks

`.claude/hooks/` contains only relative symlinks into this directory: the thirteen shipped `.md` and `.sh` injector/gate files, plus the repo-local `stop-turn-log.sh`, for fourteen entries total. The thirteen shipped files mean this repo dogfoods the same hooks it ships as a plugin; `stop-turn-log.sh` is the one repo-local exception (see below). Edit files here; never edit through the mirror.

## stop-turn-log.sh

A Stop hook that appends one JSONL line per turn to a local log, unconditionally (no enable flag). It is repo-local: registered in `.claude/settings.json` only, and is deliberately not shipped via `hooks/hooks.json`. It never blocks and never judges the turn -- pure passive logging.

## bootstrap-gate-pre.sh + bootstrap-gate-post.sh

A PreToolUse/PostToolUse pair that gates tool use in a session that has not yet completed `Skill(session-bootstrap)`. `session-start.sh` stamps three flag files on every SessionStart: `.bootstrap-pending-<session_id>`, `.honesty-pending-<session_id>`, and `.communication-pending-<session_id>`. `bootstrap-gate-post.sh` (matcher `Skill`) deletes one flag when a `Skill` call for its skill completes -- `session-bootstrap` clears the bootstrap flag, `honesty` the honesty flag, `communication` the communication flag -- and leaves the other two. `bootstrap-gate-pre.sh` (matcher: all tools, no matcher key) checks the bootstrap flag on every other tool call. The per-turn hooks read the same flags: `pre-message-gates.sh` the bootstrap flag, `pre-message.sh` the honesty and communication flags.

Mode contract, via `BOOTSTRAP_GATE_MODE`:

- `deny` (exact string) -- the shipped default, pinned by the `BOOTSTRAP_GATE_MODE=deny` prefix in both registration files. Blocks the tool call with a `permissionDecision: deny` reason instead of injecting context.
- anything else -- **warn**, the fallback: any value that isn't exactly `deny`, including unset. Allows the tool call and injects an `additionalContext` nudge to run `Skill(session-bootstrap)`.

The script's own unset default is warn (`MODE="${BOOTSTRAP_GATE_MODE:-warn}"`); the shipped default is deny only because the registration lines in both configs pin `BOOTSTRAP_GATE_MODE=deny` -- the prefix activates the mode, it isn't just documentation. There is no gate-off value -- disabling the gate means removing (or commenting out) its `PreToolUse`/`PostToolUse` entries in `.claude/settings.json` / `hooks/hooks.json`. To fall back to warn, change `BOOTSTRAP_GATE_MODE=deny` to `=warn` in the hook command lines for `bootstrap-gate-pre.sh` in both `.claude/settings.json` and `hooks/hooks.json`.

State lives under `${BOOTSTRAP_GATE_STATE_DIR:-$CLAUDE_PROJECT_DIR/.claude}`: the three flag files named above and the log `.bootstrap-gate-log.jsonl` (default path: `.claude/.bootstrap-gate-log.jsonl`), which is appended in both modes -- the JSONL write happens before the mode branch, and each logged line carries its own `mode` field.

Subagents identify themselves via an `agent_id` field on the hook payload; both `bootstrap-gate-pre.sh` and `bootstrap-gate-post.sh` ignore any call carrying one, so the gate only ever applies to the main-thread session and a subagent loading a skill never clears the main session's flags.

Accepted bootstrap skill names: both hooks strip everything through the last colon of `tool_input.skill` before comparing it to `session-bootstrap`, because the harness lists plugin skills as `<plugin>:<skill>`. So `session-bootstrap`, `story-to-ship:session-bootstrap`, and any other `<plugin>:session-bootstrap` satisfy the gate; `session-bootstrap:` (trailing colon) and `<plugin>:honesty` do not. `bootstrap-gate-post.sh` applies the same strip before matching `honesty` and `communication`, so `<plugin>:honesty` clears the honesty flag. `tools/first_action_audit/first-action-audit.sh` applies the same rule when it judges the first tool call after each `compact_boundary` record in a transcript (one BOUNDARY/listing/VERDICT block per compaction window).

Both scripts are fail-open: missing `jq`, malformed stdin, an unresolved state dir, or an invalid `session_id` all resolve to a plain allow (or, for the post-hook, a no-op) rather than blocking or guessing. Neither script ever exits nonzero.

Documented limitation: on an auto-resumed continuation, the model's first tool calls can execute before the SessionStart hook stamps the pending flag file, in which case the gate fails open (no flag file yet means a plain allow, deny mode included) for that window. The `UserPromptSubmit` hooks (`pre-message-gates.sh`, `pre-message.sh`) do not close this gap: if they run in that window they find no flag file and, when the state directory exists, inject the `-loaded` variants, which leave out the gate sections.

Documented limitation: when the state directory exists but cannot be written, `session-start.sh` stamps no flags and reports no error, so the gate allows every call and the `UserPromptSubmit` hooks inject the `-loaded` variants, which leave out the gate sections, on every turn of the session.

## workflow-model-guard.sh

A PreToolUse hook (matcher `Workflow`) that denies a Workflow tool invocation whose inline script (`tool_input.script`) dispatches an `agent(` call with no `model:` pin. Unlike bootstrap-gate, this guard is deny-only: there is no mode env var and no warn mode, because the escape hatch is the marker below, not a softer failure mode.

Block-extraction rule: a call block starts at each occurrence of the literal substring `agent(` -- per occurrence, not per line, so two calls on one line are two separate blocks -- and ends when parenthesis depth (tracked character-by-character from that occurrence's opening `(`) returns to 0 at the call's own closing paren; a nested call argument's own parens no longer terminate the block early. An unterminated block at EOF is flushed and evaluated rather than discarded. The `model:` pin check is a plain substring search scoped to that block only, so a `model:` mention in a comment line above the `agent(` occurrence, or in a preceding call on the same line, does not count. Disclosed residual: the scanner is not string-literal-aware, so literal `agent(` text or unbalanced parentheses inside a string value can shift block boundaries and produce a wrong verdict in either direction -- the marker below is the sanctioned escape hatch for a script the scanner misjudges.

Script-level opt-out: a script that carries the literal marker `WORKFLOW-MODEL-INHERIT-OK` anywhere in its text is allowed unconditionally, regardless of any unpinned calls -- this is a whole-script substring search, not scoped per-call, documenting a deliberate choice to inherit the dispatching session's model tier.

Subagents identify themselves via an `agent_id` field on the hook payload; this guard exempts any call carrying one, checked before any script parsing, matching the same exemption contract as `bootstrap-gate-pre.sh`.

This guard is fail-open: missing `jq`, malformed stdin, and a Workflow invocation with no inline `tool_input.script` (e.g. a `scriptPath`-only invocation -- out of scope for this hook by design) all resolve to a plain allow. It never exits nonzero; deny is communicated only via `permissionDecision: deny` on stdout.

## shell-write-guard.sh

A PreToolUse hook (matcher `Bash`) that denies a shell command which would overwrite an existing file that is inside a git repository and not gitignored there, because a shell overwrite bypasses the read-before-write guarantee that the Edit and Write tools provide. The protected-target rule: the target is an existing regular file (symlinks resolved), `git rev-parse --show-toplevel` succeeds from its directory, and `git check-ignore` reports it as not ignored there. Each target's own repository decides the outcome, so a file inside a nested worktree or a temporary repository under `/tmp` is protected by that repository, while files outside any repository and gitignored files (scratch and dump targets) are free to overwrite. Untracked-but-not-ignored files are protected the same as tracked ones.

Mechanisms recognized: truncating redirects (`>`, `>|`, `N>`, `&>`, `exec >`, `: >`), `tee` without `-a`, `sed -i`, `perl -i`, `ruby -i`, `cp`, `mv`, `install`, `rsync`, `ln -f`, `dd of=`, `truncate`, and inline python/node snippets (after `-c`, `-e`, `-p`, or in a heredoc body) that open a path in write mode or call `writeFileSync`. Nested `bash -c`/`sh -c`/`eval` strings, `$( )`, backticks, subshells, and in-command `cd` are followed. A target that is not a literal path (a variable, command substitution, or glob) is denied unless it starts with a literal `/tmp/` or `/dev/` (POSIX paths; the prefix rule has no Windows equivalent); an inline-snippet variable is resolved from a plain string assignment earlier in the same snippet. A command the scanner cannot parse safely -- an unterminated quote, heredoc, backtick, or parenthesis, or an unresolvable working directory after `cd` -- is denied, not allowed.

Unlike `workflow-model-guard.sh`, there is no marker, env var, or config option that lifts the guard for one command. The sanctioned route to overwrite a protected file is Read, then Edit or Write. Subagents are not exempt from the overwrite rule: it ignores an `agent_id` field on the hook payload, deliberately differing from the three sibling guards (`bootstrap-gate-pre.sh`, `workflow-model-guard.sh`, and `inline-edit-guard.sh`), because a subagent's shell overwrite is the same defect as one from the main session.

Main-session rule: for a call with no `agent_id` (the main session, not a dispatched subagent), the guard also denies creating a new file and appending to a file on any repository path that is not gitignored: every overwrite mechanism listed above also fires on a path that does not exist yet, and appends are caught through `>>`, `tee -a` or `--append`, and an interpreter `open()` in `a` or `x` mode. This closes the common shell routes around `inline-edit-guard.sh`, which counts the main session's Edit and Write changes; it does not close every route (see the residuals below). A dispatched subagent keeps the earlier behaviour: new files and appends are allowed for it. Paths outside any repository and gitignored paths are unaffected for every caller.

Fail-open list (disclosed, not silent): missing `jq`, missing `python3`, empty stdin, invalid JSON, a `tool_name` other than `Bash`, and an empty or missing `tool_input.command` all resolve to a plain allow. It never exits nonzero; deny is communicated only via `permissionDecision: deny` on stdout. Cost is about 40-50 ms per Bash call; the git checks only run when a candidate target has already been found.

Disclosed residuals (not caught): `git checkout --` or `git restore` onto a tracked file; formatters invoked with an in-place flag (`clang-format -i`, `prettier --write`, `gofmt -w`); interpreters other than python and node, and python file APIs other than `open(...,'w')` (for example `Path.write_text`); a script run via `source` or `bash file.sh`; `cp -r` onto a directory; shell functions and aliases; a heredoc body containing `>` is ignored as quoted text, though a heredoc written to a protected file is still caught. The check is static against the filesystem at call time, so a command that moves a file away and restores it later is denied because the file exists now. Editing `.claude/settings.json` or `hooks/hooks.json` with the Edit or Write tool to unregister the hook is not prevented by this guard -- that change is visible in `git diff` instead. For the main session, the new-file and append rule catches only the write mechanisms the scanner recognises; these get through: `touch`, `ln -s` to a new link, `curl -o` and other download-to-file tools, a read-write redirect `<>`, node `fs.appendFileSync` or `fs.openSync(..., 'a')`, and `>&` followed by a file name (which also gets past the overwrite rule, for every caller). Commands the scanner does not model get past both rules, for every caller: `git apply`, `git am`, and `patch`; the in-place editors `ed`, `vim -es`, `awk -i inplace`, and `sponge`; and a script file run by an interpreter (`python3 script.py`, `node script.js`). If `git` is not on `PATH` or a git call times out, the candidate target is denied (the guard fails closed on those two errors, unlike the jq/python3 fail-open cases). A nonzero exit from the repository lookup (`git rev-parse`) means "not a repository" and the write is allowed; once the target is known to be inside a repository, only a successful `git check-ignore` match frees it, and any other check-ignore result or error leaves it protected.

## inline-edit-guard.sh

A PreToolUse hook (matcher `Edit|Write`) that limits what the main session may edit itself, instead of dispatching an implementer subagent. The main session's own edits (its inline lane) are allowed only for prose files and only while small; code, configuration, and larger changes are denied with a reason that says to dispatch an implementer. Dispatched subagents are exempt: a call carrying an `agent_id` field on the hook payload is allowed without being measured, because implementers edit code in their own worktrees by design.

Prose allowlist: the resolved path's extension (symlinks resolved first) must be in `INLINE_EDIT_PROSE_EXTENSIONS`, default `md txt`, compared case-insensitively; any other extension is denied.

What counts: the changed lines of the edit, as insertions plus deletions of a line diff with no context lines. An Edit call compares `old_string` with `new_string` (multiplied by the number of occurrences in the file when `replace_all` is set); a Write call compares the file on disk with the new content, so every line of a new file counts. A changed line has no length limit: one long line counts as one line however many characters it holds. Two caps apply: `INLINE_EDIT_MAX_LINES` (default 10) changed lines per file per session, and `INLINE_EDIT_SESSION_MAX` (default 30) changed lines across the session. An edit that would take either total past its cap is denied. Each allowed edit is appended to a per-session ledger, `<state dir>/.inline-edit-ledger-<session_id>.jsonl`, where the state dir is `${BOOTSTRAP_GATE_STATE_DIR:-$CLAUDE_PROJECT_DIR/.claude}`; a denied edit is never recorded. A cap value that is not a non-negative integer falls back to its default, and an empty or whitespace-only extension list falls back to `md txt`.

Also exempt, and not counted: a path outside any git repository (including a path inside a repository's `.git` directory, where the repository lookup fails), a path that repository gitignores, and the repository's top-level `plan.md` (a `plan.md` in a subdirectory is an ordinary file).

Fail-open list (disclosed, not silent): missing `jq`, missing `python3`, empty stdin, invalid JSON, a `tool_name` other than `Edit` or `Write`, an empty `tool_input.file_path`, a state dir that cannot be resolved or does not exist, a `session_id` that is empty or holds characters outside letters, digits, dot, underscore, and hyphen, a repository lookup whose `git` call cannot run (`git` not on `PATH`, or the call times out; unlike the shell-write guard, this hook then allows), and any unexpected error in the scanner all resolve to a plain allow. It never exits nonzero; deny is communicated only via `permissionDecision: deny` on stdout.

Disclosed residuals (not caught): the ledger is per session, so work continued in a new session starts again at zero; `NotebookEdit` is not matched; shell writes are the shell-write guard's job, not this hook's; an edit is counted when the hook allows it, before the tool runs, so a tool call that then fails still uses budget; and parallel Edit or Write calls in one turn each read the ledger before any of them records its edit, so together they can pass a cap that each stayed under; and when the ledger cannot be written (for example, the ledger cannot be created in a read-only state dir, or the ledger file itself is read-only), the edit is still allowed and not recorded, so the running totals stop at what the ledger already holds, and with no ledger each edit is checked against the caps on its own size alone; and the ledger is not protected from the shell (by default it sits in a gitignored path, which the shell-write guard leaves alone), so deleting it, emptying it, or making it unreadable resets the running totals to zero.
