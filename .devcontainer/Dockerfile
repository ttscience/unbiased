FROM ghcr.io/rocker-org/devcontainer/r-ver:4.2

RUN apt update && apt-get install -y --no-install-recommends \
  # httpuv
  libz-dev \
  # sodium
  libsodium-dev \
  # RPostgres
  libpq-dev libssl-dev

ENV RENV_CONFIG_SANDBOX_ENABLED=FALSE
