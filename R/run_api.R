#' Run API
#'
#' @description
#' Starts \pkg{unbiased} API.
#'
#' @param host `character(1)`\cr
#'  Host URL.
#' @param port `integer(1)`\cr
#'  Port to serve API under.
#'
#' @return Function called to serve the API in the caller thread.
#'
#' @export
run_unbiased <- function(host = "0.0.0.0", port = 3838, ...) {
  assign("db_connection_pool", create_db_connection_pool(), envir = globalenv())
  on.exit({
    pool::poolClose(db_connection_pool)
    assign("db_connection_pool", NULL, envir = globalenv())
  })

  plumber::plumb_api("unbiased", "unbiased_api") |>
    plumber::pr_run(host = host, port = port, ...)
}

run_unbiased_local <- function(host = "0.0.0.0", port = 3838, ...) {
  assign("db_connection_pool", create_db_connection_pool(), envir = globalenv())
  on.exit({
    pool::poolClose(db_connection_pool)
    assign("db_connection_pool", NULL, envir = globalenv())
  })

  plumber::plumb("./inst/plumber/unbiased_api/plumber.R") |>
    plumber::pr_run(host = host, port = port, ...)
}
