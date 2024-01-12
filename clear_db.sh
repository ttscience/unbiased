#!/bin/bash

set -e

export PGPASSWORD="$POSTGRES_PASSWORD"

# Clear the database
psql -v ON_ERROR_STOP=1 \
    --host "$POSTGRES_HOST" \
    --port "${POSTGRES_PORT:-5432}" \
    --username "$POSTGRES_USER" \
    --dbname "$POSTGRES_DB" \
    -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
