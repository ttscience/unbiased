#!/bin/bash

set -e

DB_NAME_SUFFIX="__test"

ORIGINAL_DB_NAME="$POSTGRES_DB"
POSTGRES_DB="${ORIGINAL_DB_NAME}${DB_NAME_SUFFIX}"
UNBIASED_PORT=3899
UNBIASED_HOST="localhost"

echo "Running tests"

export POSTGRES_DB UNBIASED_PORT UNBIASED_HOST
R --quiet --no-save -e "devtools::load_all(); testthat::test_package('unbiased')"
