#!/bin/bash
# Callgrind profiling wrapper for nextest
#
# Add to .config/nextest.toml:
#   [scripts.wrapper.callgrind]
#   command = 'path/to/callgrind-wrapper.sh'
#
#   [profile.callgrind]
#   platform = 'cfg(target_os = "linux")'
#   run-wrapper = 'callgrind'
#   test-threads = 1
#
# Usage:
#   cargo nextest run --profile callgrind my_test
#
# Output goes to callgrind.out.<pid> in current directory
# Analyze with: callgrind_annotate callgrind.out.*
# Or GUI: kcachegrind callgrind.out.*

OUTFILE="${CALLGRIND_OUT:-callgrind.out}"

exec valgrind --tool=callgrind \
    --callgrind-out-file="$OUTFILE.%p" \
    --cache-sim=yes \
    --branch-sim=yes \
    "$@"
