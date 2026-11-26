#!/usr/bin/env bash
set -eu
mkdir -p notes/d.md
printf 'TASK: a one\nTASK: a two\nnote a\n' > notes/a.md
printf 'TASK: d one\nTASK: d two\nTASK: d three\nTASK: d four\nTASK: d five\n' > notes/d.md/part1.md
printf 'TASK: b one\nTASK: b two\nTASK: b three\nnote b\n' > notes/b.md
printf 'TASK: c one\nnote c\n' > notes/c.md
printf 'TASK: e one\nTASK: e two\nTASK: e three\nTASK: e four\n' > notes/e.md
printf 'TASK: f one\nTASK: f two\nnote f\n' > notes/f.md
