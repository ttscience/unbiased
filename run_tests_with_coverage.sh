#!/bin/bash

set -e

echo "Running tests"

R --quiet --no-save -e "devtools::load_all(); covr::package_coverage('.')"
