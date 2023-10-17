FROM rocker/r-ver:4.3.1

WORKDIR /src/unbiased

# Install system dependencies
RUN apt update && apt-get install -y --no-install-recommends \
  # httpuv
  libz-dev \
  # sodium
  libsodium-dev

COPY ./renv ./renv
COPY .Rprofile .
COPY renv.lock .

RUN R -e 'renv::restore()'

COPY api/ ./api

ENV RENV_CONFIG_SANDBOX_ENABLED=FALSE

EXPOSE 3838

RUN ["R", "-e", "plumber::plumb(dir = 'api') |> plumber::pr_run(port = 3838)"]
