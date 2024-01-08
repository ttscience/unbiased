FROM ghcr.io/rocker-org/devcontainer/tidyverse:4

RUN apt update && apt-get install -y --no-install-recommends \
  # httpuv
  libz-dev \
  # sodium
  libsodium-dev \
  # RPostgres
  libpq-dev libssl-dev
