#!/bin/bash

set -e

echo "Running database migrations"

echo "Using database $POSTGRES_DB"

DB_CONNECTION_STRING="postgres://$POSTGRES_USER:$POSTGRES_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$POSTGRES_DB?sslmode=disable"

# Run the migrations, pass command line arguments to the migration tool
migrate -database "$DB_CONNECTION_STRING" -path ./inst/db/migrations "$@"