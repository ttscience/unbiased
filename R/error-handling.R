# hack to make sure we can mock the globalCallingHandlers
# this method needs to be present in the package environment for mocking to work
# linter disabled intentionally since this is internal method  and cannot be renamed
globalCallingHandlers <- NULL # nolint

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

wrap_endpoint <- function(z) {
  f <- function(...) {
    return(withCallingHandlers(z(...), error = rlang::entrace))
  }
  return(f)
}

setup_invalid_json_handler <- function(api) {
  api |>
    plumber::pr_filter("validate_input_json", \(req, res) {
      if (length(req$bodyRaw) > 0) {
        request_body <- req$bodyRaw |> rawToChar()
        e <- tryCatch(
          {
            jsonlite::fromJSON(request_body)
            NULL
          },
          error = \(e) e
        )
        if (!is.null(e)) {
          print(glue::glue("Invalid JSON; requested endpoint: {req$PATH_INFO}"))
          audit_log_set_event_type("malformed_request", req)
          res$status <- 400
          return(list(
            error = jsonlite::unbox("Invalid JSON"),
            details = e$message |> strsplit("\n") |> unlist()
          ))
        }
      }

      plumber::forward()
    })
}

# nocov start
default_error_handler <- function(req, res, error) {
  print(error, simplify = "branch")

  if (sentryR::is_sentry_configured()) {
    if ("trace" %in% names(error)) {
      error$function_calls <- error$trace$call
    } else if (!("function_calls" %in% names(error))) {
      error$function_calls <- sys.calls()
    }

    sentryR::capture_exception(error)
  }

  res$status <- 500

  list(
    error = "500 - Internal server error"
  )
}
# nocov end

with_err_handler <- function(expr) {
  withCallingHandlers(
    expr = expr,
    error = rlang::entrace, bottom = rlang::caller_env()
  )
}
