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
  assignInMyNamespace("CONN", connect_to_db())

  on.exit({
    DBI::dbDisconnect(CONN)
    assignInMyNamespace("CONN", NULL)
  })

  plumber::plumb(dir = fs::path_package("unbiased", "api")) |>
    plumber::pr_run(host = host, port = port, ...)
}
