#!/usr/bin/env bash
set -eu
if [ -e .git ] || [ -e .claude-plugin ]; then echo "refusing: not an empty scratch directory" >&2; exit 1; fi
cat > session.jsonl <<'JSONL'
{"type":"user","message":{"role":"user","content":"Review the settings tool for input handling."}}
{"type":"assistant","message":{"model":"lead","content":[{"type":"tool_use","name":"Agent","input":{"model":"haiku","prompt":"Read src/parse.py and list its functions."}}]}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"parse_line, parse_text"}]}}
{"type":"assistant","message":{"model":"lead","content":[{"type":"tool_use","name":"Agent","input":{"model":"haiku","prompt":"Read src/store.py and list its functions."}}]}}
{"type":"assistant","message":{"model":"lead","content":[{"type":"text","text":"Plan: use 3 sonnet agents for the review."}]}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"save, load"}]}}
{"type":"assistant","message":{"model":"lead","content":[{"type":"tool_use","name":"Agent","input":{"model":"sonnet","prompt":"Read src/cli.py and list its functions."}}]}}
{"type":"user","message":{"role":"user","content":[{"type":"tool_result","content":"main"}]}}
{"type":"assistant","message":{"model":"lead","content":[{"type":"tool_use","name":"Agent","input":{"model":"haiku","prompt":"Check README.md against the code."}}]}}
JSONL
cat > README.md <<'MD'
# Run record

Transcript of the last run, one JSON object per line in session.jsonl.
MD
