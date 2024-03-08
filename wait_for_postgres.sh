#!/bin/bash

set -e

# PostgreSQL connection
host="${POSTGRES_HOST}"
port="${POSTGRES_PORT:-5432}"
user="${POSTGRES_USER}"
password="${POSTGRES_PASSWORD}"
database="${POSTGRES_DB}"

echo "Waiting for PostgreSQL to be ready..."
# Wait for PostgreSQL
until PGPASSWORD="${password}" psql -h $host -p $port -U $user -d $database -c '\q'; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

echo "PostgreSQL is up"