#!/bin/bash
# Valgrind wrapper for nextest
#
# Add to .config/nextest.toml:
#   [scripts.wrapper.valgrind]
#   command = 'path/to/valgrind-wrapper.sh'
#
#   [profile.valgrind]
#   platform = 'cfg(target_os = "linux")'
#   run-wrapper = 'valgrind'

exec valgrind \
    --leak-check=full \
    --show-leak-kinds=all \
    --errors-for-leak-kinds=definite,indirect \
    --error-exitcode=1 \
    "$@"
