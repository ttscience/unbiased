#!/bin/bash

set -e

DB_NAME_SUFFIX="__test"

ORIGINAL_DB_NAME="$POSTGRES_DB"
TEST_DB_NAME="${ORIGINAL_DB_NAME}${DB_NAME_SUFFIX}"
UNBIASED_PORT=3899

# Set a dummy GITHUB_SHA based on git ref HEAD
GITHUB_SHA=$(git rev-parse HEAD)

# Create a new database for testing
echo "Creating test database $TEST_DB_NAME"
./run_psql.sh -c "CREATE DATABASE $TEST_DB_NAME" || \
    echo "Cannot create $TEST_DB_NAME, assuming it already exists"

echo "Using test database $TEST_DB_NAME"
POSTGRES_DB="${TEST_DB_NAME}"

export POSTGRES_DB UNBIASED_PORT GITHUB_SHA

# Clear the test database
./clear_db.sh

# Run the migrations
./migrate_db.sh up

# Run the unbiased API
./start_unbiased_api.sh