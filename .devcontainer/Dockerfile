FROM ghcr.io/rocker-org/devcontainer/r-ver:4.2

RUN apt update && apt-get install -y --no-install-recommends \
  # httpuv
  libz-dev \
  # sodium
  libsodium-dev \
  # RPostgres
  libpq-dev libssl-dev postgresql-client \
  # R_X11
  libxt-dev

RUN pip install watchdog[watchmedo]

ENV RENV_CONFIG_SANDBOX_ENABLED=FALSE

# Install database migration tool
RUN curl -L https://packagecloud.io/golang-migrate/migrate/gpgkey | apt-key add - && \
  echo "deb https://packagecloud.io/golang-migrate/migrate/ubuntu/ focal main" > /etc/apt/sources.list.d/migrate.list && \
  apt-get update && \
  apt-get install -y migrate
