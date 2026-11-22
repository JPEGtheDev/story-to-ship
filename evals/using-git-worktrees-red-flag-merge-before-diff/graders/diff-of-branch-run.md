---
type: tool_used
tool: Bash
input_match: 'git\s+((-C\s+\S+|-c\s+\S+|--\S+)\s+)*diff\b(?![^\n\\;&|]*(\s-s\b|--(stat|shortstat|numstat|dirstat|name-only|name-status|quiet|check|no-patch|raw|summary|compact-summary)\b))[^\n\\;&|]*\.\.\.\S*agent/'
min: 1
---

Behavior: the run reads the diff of the implementer's branch against its base, in the `<base>...agent/<name>` form that the merge-before-diff Red Flag at SKILL.md:122 names. A run that never runs this diff fails. Diff forms that print no patch text are rejected: `--stat`, `--shortstat`, `--numstat`, `--dirstat`, `--name-only`, `--name-status`, `--quiet`, `--check`, `--no-patch`, `-s`, `--raw`, `--summary` and `--compact-summary`. A piped or redirected full diff (`| head`, `> file`) still matches. The check is a command form, so no judge is needed for the presence of the diff. `git diff --exit-code` prints the full patch, so it matches. Whether the diff came before the merge is checked by the regex grader `diff-before-merge`.
