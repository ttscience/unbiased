library(checkmate)
library(dplyr)
library(dbplyr)
library(httr2)

api_host <- Sys.getenv("UNBIASED_HOST", "api")
api_port <- as.integer(Sys.getenv("UNBIASED_PORT", "3838"))

api_url <- glue::glue("http://{api_host}:{api_port}")
print(glue::glue("API URL: {api_url}"))

# Retry a request until the API starts
request(api_url) |>
  # Endpoint that should be always available
  req_url_path("meta", "sha") |>
  req_method("GET") |>
  req_retry(max_tries = 5) |>
  req_perform()
