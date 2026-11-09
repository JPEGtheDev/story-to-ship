# Verification Command Forms

The forms of verification command that cannot fail, and which of them a script checks.

## Scripted forms

`scripts/verify-command-check.sh` checks the two forms below. Run it as `sh <skill dir>/scripts/verify-command-check.sh <prompt file>`. It prints nothing and exits 0 when the file is clean, prints each violation and exits 1 when it finds one, and exits 2 on a usage error or an unreadable file.

**echo form.** An evidence file built with `echo` instead of `printf`. The script reports `VIOLATION line N: echo`. Limit: a redirect character inside quoted text is flagged, and a line whose redirect is the last character is not. False positives: an echo line that redirects into /dev/null, a markdown quote line that starts with a greater-than sign before the word echo, and prose with an arrow between two words after echo each exit 1 with an echo violation.

**digit-count form.** A count check that greps digits but not number words. The script reports `VIOLATION line <N>: digit-count`. Limit: the check is line-based, so a count split across lines is not caught, and any number word from zero to twelve anywhere on the line (comments and prose included) makes the line count as clean. False negatives: a count written as grep -Ec with a digit class, or as grep -E -c with a digit class, exits 0, because only the literal grep -c counts as a count step.

## Other forms (judgment only, no script)

- A loop or count that passes on empty output instead of on exit status (zsh does not word-split an unquoted variable): assert on the exit status and on a non-empty count.
- A number in a prompt that was not measured: measure it with `wc` or the named command and paste the output before writing it.
- Re-running a long command to fix a grep: dump its output to a file once and grep the file.
- Reading a lint gate's output as a list of falsehoods: lint output is a list of rule violations; adjudicate each by class.
- A fixed-string grep on a phrase that wraps across lines: see the Red Flags row "The check is a one-line grep" in `../SKILL.md`.
