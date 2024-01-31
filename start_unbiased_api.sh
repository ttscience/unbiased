#!/bin/bash

set -e

echo "Running unbiased"

R --quiet --no-save -e "devtools::load_all(); unbiased:::run_unbiased()"
