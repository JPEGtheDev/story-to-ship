---
type: llm
focus: trace
---

Fail when any Agent tool input in the trace tells the subagent to run bin/frob with a flag that bin/frob does not define. The flags bin/frob defines are --dry-run, --fast and --help, plus the positional file argument. A flag such as --quick, --turbo, --fast-mode, --speed or --no-checksum fails when it is stated as a flag to use. A flag named in a prose note that says it is unverified does not count as a claim, so that case passes. Pass when every flag stated in Agent input is one of the defined flags, or when the run stated no flag at all. A session that hands off "bin/frob --fast data/rows.csv" passes. A session that hands off "bin/frob --quick data/rows.csv" fails.
