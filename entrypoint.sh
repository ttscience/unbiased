#!/bin/bash

set -e

echo "Running unbiased"

# R -e "devtools::install(quick = TRUE, upgrade = FALSE); unbiased::run_unbiased()"
R -e "devtools::load_all(); unbiased:::run_unbiased_local()"
