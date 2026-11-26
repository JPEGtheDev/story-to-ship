#!/usr/bin/env bash
set -eu
printf 'name: sync-worker\ntimeout: 30\nretries: 3\nlog_level: info\nregion: us-east\n' > config.old.yaml
printf 'name: sync-worker\ntimeout: 45\nretries: 5\nlog_level: debug\nregion: us-east\n' > config.new.yaml
