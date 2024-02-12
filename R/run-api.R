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
  tryCatch(
    {
      rlang::global_entrace()
    },
    error = function(e) {
      message("Error setting up global_entrace, it is expected in testing environment: ", e$message)
    }
  )
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
    plumber::plumb("./inst/plumber/unbiased_api/plumber.R") |>
      plumber::pr_run(host = host, port = port)
  }
}


#' setup_sentry function
#'
#' This function is used to configure Sentry, a service for real-time error tracking.
#' It uses the sentryR package to set up Sentry based on environment variables.
#'
#' @param None
#'
#' @return None. If the SENTRY_DSN environment variable is not set, the function will
#' return a message and stop execution.
#'
#' @examples
#' setup_sentry()
#'
#' @details
#' The function first checks if the SENTRY_DSN environment variable is set. If not, it
#' returns a message and stops execution.
#' If SENTRY_DSN is set, it uses the sentryR::configure_sentry function to set up Sentry with
#' the following parameters:
#' - dsn: The Data Source Name (DSN) is retrieved from the SENTRY_DSN environment variable.
#' - app_name: The application name is set to "unbiased".
#' - app_version: The application version is retrieved from the GITHUB_SHA environment variable.
#'    If not set, it defaults to "unspecified".
#' - environment: The environment is retrieved from the SENTRY_ENVIRONMENT environment variable.
#'    If not set, it defaults to "development".
#' - release: The release is retrieved from the SENTRY_RELEASE environment variable.
#'    If not set, it defaults to "unspecified".
#'
#' @seealso \url{https://docs.sentry.io/}
setup_sentry <- function() {
  sentry_dsn <- Sys.getenv("SENTRY_DSN")
  if (sentry_dsn == "") {
    message("SENTRY_DSN not set, skipping Sentry setup")
    return()
  }

  sentryR::configure_sentry(
    dsn = sentry_dsn,
    app_name = "unbiased",
    app_version = Sys.getenv("GITHUB_SHA", "unspecified"),
    environment = Sys.getenv("SENTRY_ENVIRONMENT", "development"),
    release = Sys.getenv("SENTRY_RELEASE", "unspecified")
  )

  globalCallingHandlers(
    error = global_calling_handler
  )
}

global_calling_handler <- function(error) {
  error$function_calls <- sys.calls()
  sentryR::capture_exception(error)
  signalCondition(error)
}
