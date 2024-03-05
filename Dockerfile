FROM rocker/r-ver:4.2.3

WORKDIR /src/unbiased

# Install system dependencies
RUN apt update && apt-get install -y --no-install-recommends \
  # httpuv
  libz-dev \
  # sodium
  libsodium-dev \
  # RPostgres
  libpq-dev libssl-dev postgresql-client \
  curl gnupg2

# Install database migration tool
RUN curl -L https://packagecloud.io/golang-migrate/migrate/gpgkey | apt-key add - && \
  echo "deb https://packagecloud.io/golang-migrate/migrate/ubuntu/ focal main" > /etc/apt/sources.list.d/migrate.list && \
  apt-get update && \
  apt-get install -y migrate

ENV RENV_CONFIG_SANDBOX_ENABLED=FALSE

COPY ./renv ./renv
COPY .Rprofile .

# Both renv.lock and DESCRIPTION are needed to restore the R environment
COPY renv.lock .
COPY DESCRIPTION .

RUN R -e 'renv::restore()'

COPY .Rbuildignore .
COPY NAMESPACE .
COPY inst/ ./inst
COPY R/ ./R
COPY tests/ ./inst/tests

RUN R -e "devtools::install('.')"

EXPOSE 3838

ARG github_sha
ENV GITHUB_SHA=${github_sha}

CMD ["R", "-e", "unbiased::run_unbiased()"]