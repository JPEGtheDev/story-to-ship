#!/usr/bin/env bash
set -eu
if [ -e .git ] || [ -e .claude-plugin ]; then echo "refusing: not an empty scratch directory" >&2; exit 1; fi
mkdir -p docs
printf '%s\n' \
  "# Setup" \
  "" \
  "Install the tool with the steps below." \
  $'Step one creates a config file in the home folder.' \
  $'Step two runs the first sync \xe2\x80\x94 it may take a minute.' \
  "Step three checks the result against the sample output." > docs/setup.md
printf '%s\n' \
  "# Usage" \
  "" \
  "Run the tool with a source folder and a target folder." \
  $'The flag -v prints each file as it is copied \xe2\x80\x94 useful for debugging.' \
  "Exit code zero means the copy finished." \
  "Any other exit code means an error was reported on stderr." > docs/usage.md
printf '%s\n' \
  "# FAQ" \
  "" \
  $'Does it need network access? No \xe2\x80\x94 everything runs locally.' \
  "Can it skip hidden files? Yes, with the skip option." \
  "Where are logs kept? In the logs folder under the install root." > docs/faq.md
printf '%s\n' \
  "# Naming" \
  "" \
  $'The docs call the feature \xe2\x80\x9csync mode\xe2\x80\x9d in most places.' \
  $'Older pages say \xe2\x80\x9cmirror mode\xe2\x80\x9d for the same thing.' \
  "Pick one name when you edit a page." \
  "Both names still work in the config file." > docs/naming.md
printf '%s\n' \
  "# Flow" \
  "" \
  $'Input files go to the parser \xe2\x86\x92 the writer \xe2\x86\x92 the output folder.' \
  "The parser skips empty lines." \
  "The writer keeps file order." \
  "Errors stop the run at the first bad file." > docs/flow.md
printf '%s\n' \
  "# Limits" \
  "" \
  "The tool handles files up to 2 GB." \
  "Larger files need the chunked mode." \
  "Chunks are 256 MB by default." \
  "Set the chunk size in the config file." > docs/limits.md
printf '%s\n' \
  "# docs-sample" \
  "" \
  "Sample docs folder for the build check." \
  "Each page lives in docs/." > README.md
