#!/bin/bash

set -e

export PGPASSWORD="$POSTGRES_PASSWORD"

psql --host "$POSTGRES_HOST" \
    --port "${POSTGRES_PORT:-5432}" \
    --username "$POSTGRES_USER" \
    --dbname "$POSTGRES_DB" \
    "$@"
