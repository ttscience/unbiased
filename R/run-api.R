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
run_unbiased <- function() {
  setup_sentry()
  host <- Sys.getenv("UNBIASED_HOST", "0.0.0.0")
  port <- as.integer(Sys.getenv("UNBIASED_PORT", "3838"))
  assign("db_connection_pool",
    unbiased:::create_db_connection_pool(),
    envir = globalenv()
  )

  on.exit({
    db_connection_pool <- get("db_connection_pool", envir = globalenv())
    pool::poolClose(db_connection_pool)
    assign("db_connection_pool", NULL, envir = globalenv())
  })

  # if "inst" directory is not present, we assume that the package is installed
  # and inst directory content is copied to the root directory
  # so we can use plumb_api method
  if (!dir.exists("inst")) {
    plumber::plumb_api("unbiased", "unbiased_api") |>
      plumber::pr_run(host = host, port = port)
  } else {
    # otherwise we assume that we are in the root directory of the repository
    # and we can use plumb method to run the API from the plumber.R file

    # Following line is excluded from code coverage because it is not possible to
    # run the API from the plumber.R file in the test environment
    # This branch is only used for local development
    plumber::plumb("./inst/plumber/unbiased_api/plumber.R") |> # nocov start
      plumber::pr_run(host = host, port = port) # nocov end
  }
}
