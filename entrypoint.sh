#!/bin/bash
set -e

./wait_for_postgres.sh
./migrate_db.sh up
./start_unbiased_api.sh
