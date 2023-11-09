FROM rocker/r-ver:4.2.1

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

COPY .Rbuildignore .
COPY DESCRIPTION .
COPY NAMESPACE .
COPY inst/ ./inst
COPY R/ ./R
COPY tests/ ./inst/tests

RUN R CMD INSTALL --no-multiarch .

EXPOSE 3838

ARG github_sha
ENV GITHUB_SHA=${github_sha}

CMD ["R", "-e", "plumber::plumb(dir = fs::path_package('unbiased', 'api')) |> plumber::pr_run(host = '0.0.0.0', port = 3838)"]
