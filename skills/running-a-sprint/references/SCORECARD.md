# Sprint scorecard

This file is the launcher's scoring template. A runner is a coordinator subagent (the story-coordinator template) that runs one story and hands back. Write the predictions before launch and count the measures after the runner's pull request (PR) merges, so every sprint is scored alike.

## Predictions

Copy these lines into the sprint ledger before launch. After the merge, append `-- held` or `-- missed` to each.

- The first call is session-bootstrap alone, then honesty, then communication.
- Worktree isolation holds: the main checkout stays on main, with no checkout, switch or stash in its reflog.
- The plan file stays out of the main checkout and out of the PR.
- Dispatch count is at least the children the story needs: an implementer, a Stage 1 reviewer and a Stage 2 reviewer per todo.
- Review verdicts are present in the PR body.
- Child visibility holds: while the runner is live, every child's transcript is readable from the launcher.

## Measures

Set these variables: T is the runner transcript (a JSON Lines file), L the launcher transcript, D the launcher session folder, R the main checkout, S the merge commit, W the runner's feature worktree, F a file an inline edit touched. Define the counters once.

```bash
calls() { jq -nc --arg n "$1" '[inputs|select(.type=="assistant")|.message.content[]?|select(.type=="tool_use" and .name==$n)]' "$T"; }
handbacks() { jq -nc '[inputs|select(.type=="assistant")|.message.content[]?|select(.type=="text")|.text|select(test("^(owner question|PR ready|blocked|cap reached|interim)";"i"))]' "$T"; }
first_skills() { calls Skill | jq -c 'map(.input.skill)[0:3]'; }
cd_count() { calls Bash | jq 'map(select(.input.command|test("(^|[;&|(\\s])cd [^;&|\\n]*\\.worktrees/")))|length'; }
bg_count() { calls Agent | jq -c 'map(.input.run_in_background)|[(map(select(.==true))|length), (map(select(.!=false))|length)]'; }
dispatch_count() { calls Agent | jq 'length'; }
nomodel_count() { calls Agent | jq 'map(select((.input.model//"")==""))|length'; }
merge_calls() { calls Bash | jq 'map(select(.input.command|test("gh pr merge")))|length'; }
plan_outside() { calls Write | jq 'map(select(.input.file_path|test("plan\\.md$") and (test("\\.worktrees/")|not)))|length'; }
handback_check() { handbacks | jq -c '[length, (map(select(test("Discovery: (ran|skipped: issue carries a Feature Specification)")))|length), (map(select(test("reload";"i")))|length)]'; }
owner_q() { handbacks | jq 'map(select(test("^owner question";"i")))|length'; }
number_seen() { jq -nc --arg n "$1" '[inputs|select(.type=="user")|.message.content[]?|select(.type=="tool_result")|(.content|if type=="array" then map(.text//"")|join("") else (.//"") end)|select(contains($n))]|length' "$T"; }
missing_children() { grep -oE 'agentId: a[0-9a-f]+' "$T" | sort -u | cut -d' ' -f2 | while read -r id; do [ -f "$D/subagents/agent-$id.jsonl" ] || echo "$id"; done | wc -l; }
turn_kinds() { jq -nc '[inputs|select(.type=="user")|.origin.kind//"none"]|group_by(.)|map({kind:.[0],n:length})' "$L"; }
tokens() { grep -oE '(subagent|total)_tokens: [0-9]+' "$L"; }
```

```bash
reflog_checkouts() { git -C "$R" reflog show --format='%gs' --since="$1" HEAD | grep -c '^checkout:'; }
stash_count() { git -C "$R" stash list | wc -l; }
plan_in_diff() { git -C "$R" diff --name-only "$S^" "$S" | grep -c -x 'plan.md'; }
lane_sum() { for h in "$@"; do git -C "$W" diff --numstat "$h^" "$h" -- "$F"; done | awk '{s+=$1+$2} END{print s+0}'; }
```

The grep -c counters (reflog_checkouts, plan_in_diff) exit 1 on a zero count. Run each counter on a tiny input that must give 0 before trusting it.

| Measure | Counting command or source | How to read it |
|---|---|---|
| First three skill calls | `first_skills` | Expect session-bootstrap, honesty, communication in that order. |
| First-action audit verdict | The next section | CLEAN is a pass; MISS is a miss. |
| cd into worktrees count (the never-cd gate; launcher-side) | `cd_count` | Counts Bash calls that cd into a path under .worktrees/. Expect 0. |
| Background children count | `bg_count` | Prints [explicit true, not explicitly false]; an omitted value runs in the background here. Expect [0,0]. |
| Dispatch count | `dispatch_count` | Three children per todo; fewer means a skipped stage. |
| Model passed on every dispatch | `nomodel_count` | Counts Agent calls whose input lacks a model. Expect 0. |
| Main-checkout reflog checkout lines | `reflog_checkouts "<launch time>"`, `stash_count` | Switch logs as checkout. Expect 0 since launch and a stash count equal to the count before launch. |
| Plan file not in the PR diff | `plan_in_diff`, `plan_outside` | Expect 0 and 0: no plan file in the merge, no plan Write outside .worktrees/. |
| Discovery line present in every hand-back after planning | `handback_check` | Prints [hand-backs, with a valid Discovery line, naming reloads]. Expect three equal numbers. |
| Skills reloaded at each todo pickup and after each resume | `handback_check` (third number) and the reload list in each hand-back | Every pickup and resume needs a listed reload. |
| Lane entries vs git diff | `lane_sum <inline commit hashes>` per file | Compare with n in the plan entry lane: inline n lines in file; a mismatch is a finding. |
| Hand-back numbers vs the runner's own tool output | `number_seen "<number>"` for three numbers | Expect 1 or more each; confirm the match ran in the same turn. |
| Owner-reserved item decided without an owner question | `merge_calls` and a read of each hand-back | Reserved: merge, fix-round cap override, scope change. Expect 0. |
| Owner questions relayed | `owner_q` | Must match the questions the ledger shows relayed to the owner. |
| Launcher turns spent on relay and monitoring | `turn_kinds` | Count task-notification and peer turns after launch. Unverified: the origin kind values were not checked against a real launcher transcript; open one and confirm them before trusting this count. |
| Runner tokens per segment | `tokens` | One figure per completion notification (a segment is one launch or resume); report each. Unverified: the field name was seen only inside child results, not in a real completion notification; confirm it against a real notification, and read the figure off the notification by hand if the counter prints nothing. |
| Child visibility | `missing_children` | Run while the runner is live. Expect 0 missing child transcripts. |
| Correction-source ratio | Dispatch the postmortem-reviewer template on the runner transcript | Report externally-caught / (self-caught + externally-caught) from its Correction-source audit row. Fewer than ten corrections is a small-sample reading. |

## Auditing a subagent transcript

The first-action audit script skips every record whose isSidechain is true, and every record in a subagent transcript is sidechain. On the original it prints NO_TOOL_CALLS, which looks like a pass but audited nothing. Audit a copy with isSidechain set to false on every record:

```bash
jq -c '.isSidechain=false' "$T" > "$C"
bash tools/first_action_audit/first-action-audit.sh "$C" 5
```

The script prints one BOUNDARY block per window, a window being the span after a compaction boundary (or one window tagged none). CLEAN means the window's first main-thread assistant message made exactly one tool call, Skill session-bootstrap. MISS names the first other call and exits 1. NO_TOOL_CALLS means the window held no tool call.

## Scorecard row

Copy one row per runner into the sprint ledger.

- Story: <story reference>
- Predictions held: <names> / missed: <names, or none>
- First three skill calls: <list>; first-action audit: <CLEAN or MISS>
- cd into worktrees count: <n>; background children: <explicit true, not explicitly false>
- Dispatch count: <n>; dispatches without a model: <n>
- Main-checkout reflog checkout lines: <n>; plan file in the PR diff: <n>
- Hand-backs, with Discovery line, naming reloads: <three numbers>
- Lane entries vs git diff: <match, or mismatch with both numbers>
- Hand-back numbers confirmed in tool output: <n of 3>
- Owner-reserved items decided without a question: <n>; owner questions relayed: <n>
- Launcher turns on relay and monitoring: <n>; missing child transcripts: <n>
- Runner tokens per segment: <list>
- Correction-source ratio: <ratio> from <count> corrections
- What to change: <one line>
