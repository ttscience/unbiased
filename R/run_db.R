CONN <- NULL

#' Run local DB
#'
#' @description
#' Starts a Docker container containing a Postgres database for unbiased API
#' storage and sets environment variables to allow API to connect. Do not run
#' if an external Postgres database exists already, set appropriate env vars
#' instead.
#'
#' @return Return code describing success or lack thereof.
#'
#' @export
run_unbiased_db <- function() {
  Sys.setenv(POSTGRES_DB = "postgres")
  Sys.setenv(POSTGRES_HOST = "127.0.0.1")
  Sys.setenv(POSTGRES_PORT = 5432)
  Sys.setenv(POSTGRES_USER = "postgres")
  Sys.setenv(POSTGRES_PASSWORD = "postgres")

  system(glue::glue(
    "docker run",
    "-e POSTGRES_PASSWORD={Sys.getenv('POSTGRES_PASSWORD')}",
    "-p {Sys.getenv('POSTGRES_PORT')}:5432",
    # Docker engine v23+ allows relative paths on host, so it'd be simply
    # ./inst/postgres, but v23 was pretty new when I was writing this
    "-v {fs::path_wd('inst', 'postgres')}:/docker-entrypoint-initdb.d/",
    "-d --name unbiased_db_local",
    "eddhannay/alpine-postgres-temporal-tables:latest",
    .sep = " "
  ))
}

connect_to_db <- purrr::insistently(function() {
  DBI::dbConnect(
    RPostgres::Postgres(),
    dbname = Sys.getenv("POSTGRES_DB"),
    host = Sys.getenv("POSTGRES_HOST"),
    port = Sys.getenv("POSTGRES_PORT"),
    user = Sys.getenv("POSTGRES_USER"),
    password = Sys.getenv("POSTGRES_PASSWORD")
  )
}, rate = purrr::rate_delay(2, max_times = 5))
