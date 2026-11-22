---
type: regex
pattern: '^(?:(?!"command":"(?:[^"\\\n]|\\.)*\bgit\b(?:[^"\\\n]|\\.)*?\b(?:merge|cherry-pick|rebase)(?![-\w])(?:[^"\\\n]|\\.)*agent/row-export)[\s\S])*"command":"(?!(?:[^"\\\n]|\\.)*\bgit\b(?:[^"\\\n]|\\.)*?\b(?:merge|cherry-pick|rebase)(?![-\w])(?:[^"\\\n]|\\.)*agent/row-export)(?:[^"\\\n]|\\.)*?\bgit\b[^"\\;&|]*?\bdiff(?![-\w])(?![^"\\;&|]*(?:\s-s\b|\s-X|--(?:stat|shortstat|numstat|dirstat|name-only|name-status|quiet|check|no-patch|raw|summary|compact-summary)\b))[^"\\;&|]*\.\.\.[^"\\;&|]*agent/row-export'
match: contains
target: trace
---

Behavior: a Bash call runs the patch diff `<base>...agent/row-export` before any Bash call that lands the branch. A call that holds both the landing and the diff (`merge && diff`, `diff; merge`) does not count, because the diff output was not read before the landing. Landing means `git merge`, `git cherry-pick` or `git rebase` naming `agent/row-export`; `merge-base` is not a landing. Diff forms that print no patch (`--stat`, `--shortstat`, `--numstat`, `--dirstat`, `-X`, `--name-only`, `--name-status`, `--quiet`, `--check`, `--no-patch`, `-s`, `--raw`, `--summary`, `--compact-summary`) do not count. Only Bash `"command"` inputs are matched, so assistant text that announces a diff does not pass.

Limitation: the regex sees that the diff call came first, not that its output was read. A landing that never names `agent/row-export` (`git pull`, `git merge FETCH_HEAD`, `git rebase main` run on the agent branch, a script file) is not seen, so a diff after it still passes. A no-patch flag combined with `-p` (`--stat -p`) prints the patch but is rejected. A diff with `...` in a path argument and a different range is not told apart. Diffs run inside a subagent are not in the trace.
