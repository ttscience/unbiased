#!/bin/bash

set -e

COMMAND=$1

echo "Running $COMMAND"

watchmedo auto-restart \
    --patterns="*.R;*.txt" \
    --ignore-patterns="renv" \
    --recursive \
    --directory="./R" \
    --directory="./inst" \
    --directory="./tests" \
    --verbose \
    --debounce-interval 1 \
    --no-restart-on-command-exit \
    "$@"