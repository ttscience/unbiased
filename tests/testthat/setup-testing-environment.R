library(checkmate)
library(dplyr)
library(dbplyr)
library(httr2)

run_psql <- function(statement) {
  withr::local_envvar(
    PGPASSWORD = Sys.getenv("POSTGRES_PASSWORD")
  )

  # Construct the command
  command <- paste(
    "psql",
    "--host", shQuote(Sys.getenv("POSTGRES_HOST")),
    "--port", shQuote(Sys.getenv("POSTGRES_PORT")),
    "--username", shQuote(Sys.getenv("POSTGRES_USER")),
    "--dbname", shQuote(Sys.getenv("POSTGRES_DB")),
    "--command", shQuote(statement),
    sep = " "
  )

  system(command, intern = TRUE)
}

run_migrations <- function() {
  # Construct the connection string
  user <- Sys.getenv("POSTGRES_USER")
  password <- Sys.getenv("POSTGRES_PASSWORD")
  host <- Sys.getenv("POSTGRES_HOST")
  port <- Sys.getenv("POSTGRES_PORT", "5432")
  db <- Sys.getenv("POSTGRES_DB")

  print(
    glue::glue(
      "Running migrations on database {db} at {host}:{port}"
    )
  )

  migrations_path <- glue::glue(
    "{root_repo_directory}/inst/db/migrations"
  )
  if (!dir.exists(migrations_path)) {
    # If the migrations directory does not exist
    # we will assume that the package is installed
    # and inst directory content is copied to the root directory
    migrations_path <- glue::glue(
      "{root_repo_directory}/db/migrations"
    )
  }

  db_connection_string <-
    glue::glue(
      "postgres://{user}:{password}@{host}:{port}/{db}?sslmode=disable"
    )
  command <- "migrate"
  args <- c(
    "-database",
    db_connection_string,
    "-path",
    migrations_path,
    "up"
  )

  system2(command, args)
}

create_database <- function(db_name) {
  # make sure we are not creating the database that we are using for connection
  assert(
    db_name != Sys.getenv("POSTGRES_DB"),
    "Cannot create the database that is used for connection"
  )
  print(
    glue::glue(
      "Creating database {db_name}"
    )
  )
  run_psql(
    glue::glue(
      "CREATE DATABASE {db_name}"
    )
  )
}

drop_database <- function(db_name) {
  # make sure we are not dropping the database that we are using for connection
  assert(
    db_name != Sys.getenv("POSTGRES_DB"),
    "Cannot drop the database that is used for connection"
  )
  # first, terminate all connections to the database
  print(
    glue::glue(
      "Terminating all connections to the database {db_name}"
    )
  )
  run_psql(
    glue::glue(
      "SELECT pg_terminate_backend(pg_stat_activity.pid)
      FROM pg_stat_activity
      WHERE pg_stat_activity.datname = '{db_name}'
        AND pid <> pg_backend_pid();"
    )
  )
  print(
    glue::glue(
      "Dropping database {db_name}"
    )
  )
  run_psql(
    glue::glue(
      "DROP DATABASE {db_name}"
    )
  )
}

setup_test_db_connection_pool <- function(envir = parent.frame()) {
  # We will create a connection pool to the database
  # and store it in the global environment
  # so that we can use it in the tests
  # without having to pass it around
  db_connection_pool <- unbiased:::create_db_connection_pool()
  assign("db_connection_pool", db_connection_pool, envir = globalenv())
  withr::defer(
    {
      print("Closing database connection pool")
      db_connection_pool$close()
      assign("db_connection_pool", NULL, envir = globalenv())
    },
    envir = envir
  )
}

# Make sure to disable Sentry during testing
withr::local_envvar(
  SENTRY_DSN = NULL
)

# We will always run the API on the localhost
# and on a random port
api_host <- "127.0.0.1"
api_port <- httpuv::randomPort()

api_url <- glue::glue("http://{api_host}:{api_port}")
print(glue::glue("API URL: {api_url}"))

# make sure we are in the root directory of the repository
# this is necessary to run the database migrations
# as well as to run the plumber API
current_working_dir <- getwd()
root_repo_directory <-
  glue::glue(current_working_dir, "/../../") |>
  normalizePath()
setwd(root_repo_directory)

# append __test suffix to the database name
# we will use this as a convention to create a test database
# we have to avoid messing with the original database
db_name <- Sys.getenv("POSTGRES_DB")
db_name_test <- glue::glue("{db_name}__test")

# create the test database using connection with the original database
create_database(db_name_test)

# now that the database is created, we can set the environment variable
# to the test database name
# we will be working on the test database from now on
withr::local_envvar(
  list(
    POSTGRES_DB = db_name_test
  )
)

# drop the test database upon exiting
withr::defer(
  {
    # make sure db_name_test ends with __test before dropping it
    assert(
      stringr::str_detect(db_name_test, "__test$"),
      "db_name_test should end with __test"
    )
    setwd(root_repo_directory)
    drop_database(db_name_test)
  },
  teardown_env()
)

# run migrations
exit_code <- run_migrations()
if (exit_code != 0) {
  stop(
    glue::glue(
      "Failed to run database migrations",
      "exit code: {exit_code}"
    )
  )
}

# We will run the unbiased API in the background
# and wait until it starts
# We are setting the environment variables
# so that the unbiased API will start an HTTP server
# on the specified host and port without coliision
# with the main API that might be running on the same machine
withr::local_envvar(
  list(
    UNBIASED_HOST = api_host,
    UNBIASED_PORT = api_port
  )
)

# Mock GITHUB_SHA as valid sha if it is not set
github_sha <- Sys.getenv(
  "GITHUB_SHA",
  "6e21b5b689cc9737ba0d24147ed4b634c7146a28"
)
if (github_sha == "") {
  github_sha <- "6e21b5b689cc9737ba0d24147ed4b634c7146a28"
}
withr::local_envvar(
  list(
    GITHUB_SHA = github_sha
  )
)

stdout_file <- withr::local_tempfile(
  fileext = ".log",
  .local_envir = teardown_env()
)

stderr_file <- withr::local_tempfile(
  fileext = ".log",
  .local_envir = teardown_env()
)

plumber_process <- callr::r_bg(
  \() {
    if (!requireNamespace("unbiased", quietly = TRUE)) {
      # There is no installed unbiased package
      # In that case, we will assume that we are running
      # on the development machine
      # and we will load the package using devtools
      print("Installing unbiased package using devtools")
      devtools::load_all()
    }

    unbiased:::run_unbiased()
  },
  supervise = TRUE,
  stdout = stdout_file,
  stderr = stderr_file,
)

withr::defer(
  {
    print("Server STDOUT:")
    lines <- readLines(stdout_file)
    writeLines(lines)
    print("Server STDERR:")
    lines <- readLines(stderr_file)
    writeLines(lines)
    print("Sending SIGINT to plumber process")
    plumber_process$interrupt()

    print("Waiting for plumber process to exit")
    plumber_process$wait()
  },
  teardown_env()
)

# go back to the original working directory
# that is used by the testthat package
setwd(current_working_dir)

setup_test_db_connection_pool(envir = teardown_env())

# Retry a request until the API starts
print("Waiting for the API to start...")
request(api_url) |>
  # Endpoint that should be always available
  req_url_path("meta", "sha") |>
  req_method("GET") |>
  req_retry(
    max_seconds = 30,
    backoff = \(x) 1
  ) |>
  req_perform()
print("API started, running tests...")
