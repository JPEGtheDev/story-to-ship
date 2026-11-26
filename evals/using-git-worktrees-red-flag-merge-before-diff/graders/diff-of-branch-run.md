---
type: tool_used
tool: Bash
input_match: 'git\s+((-C\s+\S+|-c\s+\S+|-P|--\S+)\s+)*diff\b(?!(?:[^\n\\;&|]|\\")*(\s-s\b|\s-X|--(stat|shortstat|numstat|dirstat|name-only|name-status|quiet|check|no-patch|raw|summary|compact-summary)\b))(?:[^\n\\;&|]|\\")*\.\.\.\S*agent/'
min: 1
---

Behavior: the run reads the diff of the implementer's branch against its base, in the `<base>...agent/<name>` form (the whole branch against its base). A run that never runs this diff fails. Diff forms that print no patch text are rejected: `--stat`, `--shortstat`, `--numstat`, `--dirstat`, `--name-only`, `--name-status`, `--quiet`, `--check`, `--no-patch`, `-s`, `--raw`, `--summary`, `--compact-summary` and `-X` (`--dirstat`'s short form). A piped or redirected full diff (`| head`, `> file`) still matches. A quoted range (`git diff "main...agent/row-export"`) and a `git -P diff` prefix match. Only the three-dot form counts: the merge-base form (`git diff $(git merge-base main agent/row-export) agent/row-export`) and the two-dot form (`main..agent/row-export`) are rejected. That is a limitation: the merge-base form reads the same patch as the three-dot form. The check is a command form, so no judge is needed for the presence of the diff. `git diff --exit-code` prints the full patch, so it matches. Whether the diff came before the merge is checked by the regex grader `diff-before-merge`.
