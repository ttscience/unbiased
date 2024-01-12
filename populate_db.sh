#!/bin/bash

set -e

export PGPASSWORD="$POSTGRES_PASSWORD"

# List all sql files in inst/postgres directory and execute them in alphabetical order
for f in inst/postgres/*.sql; do
    echo "Executing $f"
    psql -v ON_ERROR_STOP=1 \
        --host "$POSTGRES_HOST" \
        --port "${POSTGRES_PORT:-5432}" \
        --username "$POSTGRES_USER" \
        --dbname "$POSTGRES_DB" \
        -f "$f"
done