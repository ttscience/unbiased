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
  assignInMyNamespace("db_connection_pool", create_db_connection_pool())

  on.exit({
    pool::poolClose(db_connection_pool)
    assignInMyNamespace("db_connection_pool", NULL)
  })

  plumber::plumb_api('unbiased', 'unbiased_api') |>
    plumber::pr_run(host = host, port = port, ...)
}
