library(checkmate)
library(dplyr)
library(dbplyr)
library(httr2)

api_host <- Sys.getenv("UNBIASED_HOST", "api")
api_port <- as.integer(Sys.getenv("UNBIASED_PORT", "3838"))

api_url <- glue::glue("http://{api_host}:{api_port}")
print(glue::glue("API URL: {api_url}"))

working_directory <-
  glue::glue(getwd(), "/../../") |>
  normalizePath()

plumber_process <- callr::r_bg(
  \(working_directory) {
    setwd(working_directory)
    if (!requireNamespace("unbiased", quietly = TRUE)) {
      print("Installing unbiased package using devtools")
      devtools::load_all()
      unbiased:::run_unbiased_local()
    } else {
      print("Running installed unbiased package")
      unbiased:::run_unbiased()
    }
  },
  args = list(working_directory = working_directory),
)

withr::defer(
  {
    print("Server STDOUT:")
    while (length(lines <- plumber_process$read_output_lines())) {
      print(
        lines |>
          paste(collapse = "\n") |>
          stringr::str_squish()
      )
    }
    print("Server STDERR:")
    while (length(lines <- plumber_process$read_error_lines())) {
      message(
        lines |>
          paste(collapse = "\n") |>
          stringr::str_squish()
      )
    }
    print("Sending SIGINT to plumber process")
    plumber_process$interrupt()

    print("Waiting for plumber process to exit")
    plumber_process$wait()
  },
  teardown_env()
)


# Retry a request until the API starts
request(api_url) |>
  # Endpoint that should be always available
  req_url_path("meta", "sha") |>
  req_method("GET") |>
  req_retry(max_tries = 5) |>
  req_perform()
