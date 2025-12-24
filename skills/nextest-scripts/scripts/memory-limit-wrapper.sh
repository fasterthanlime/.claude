#!/bin/bash
# Memory limit wrapper for nextest using systemd-run
#
# Add to .config/nextest.toml:
#   [scripts.wrapper.limited]
#   command = 'path/to/memory-limit-wrapper.sh'
#
#   [profile.limited]
#   platform = 'cfg(target_os = "linux")'
#   run-wrapper = 'limited'
#
# Usage:
#   MEMORY_LIMIT=512M cargo nextest run --profile limited
#   MEMORY_LIMIT=1G cargo nextest run --profile limited my_test

LIMIT="${MEMORY_LIMIT:-2G}"

exec systemd-run --user --scope \
    -p MemoryMax="$LIMIT" \
    -p MemorySwapMax=0 \
    "$@"
