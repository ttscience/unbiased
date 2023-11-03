FROM rocker/r-ver:4.3.1

WORKDIR /src/unbiased

# Install system dependencies
RUN apt update && apt-get install -y --no-install-recommends \
  # httpuv
  libz-dev \
  # sodium
  libsodium-dev

ENV RENV_CONFIG_SANDBOX_ENABLED=FALSE

COPY ./renv ./renv
COPY .Rprofile .
COPY renv.lock .

RUN R -e 'renv::restore()'

COPY app/ ./app
COPY inst/api/ ./api

# Copy more package data
# Build package from app
# Or maybe separate Dockerfiles and build package in a separate image

EXPOSE 3838

ARG github_sha
ENV GITHUB_SHA=${github_sha}

CMD ["R", "-e", "plumber::plumb(dir = 'api') |> plumber::pr_run(host = '0.0.0.0', port = 3838)"]
