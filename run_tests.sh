#!/bin/bash

set -e

DB_NAME_SUFFIX="__test"

ORIGINAL_DB_NAME="$POSTGRES_DB"
POSTGRES_DB="${ORIGINAL_DB_NAME}${DB_NAME_SUFFIX}"
UNBIASED_PORT=3899
UNBIASED_HOST="127.0.0.1"

# Set a dummy GITHUB_SHA based on git ref HEAD
GITHUB_SHA=$(git rev-parse HEAD)

echo "Running tests"

export POSTGRES_DB UNBIASED_PORT UNBIASED_HOST GITHUB_SHA
R --quiet --no-save -e "devtools::load_all(); testthat::test_package('unbiased')"
