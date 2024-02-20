#' AuditLog Class
#'
#' This class is used internally to store audit logs for each request.
AuditLog <- R6::R6Class( # nolint: object_name_linter.
  "AuditLog",
  public = list(
    initialize = function(request_method, endpoint_url, request_body) {
      private$request_id <- uuid::UUIDgenerate()
      private$request_method <- request_method
      private$endpoint_url <- endpoint_url
      private$request_body <- request_body
    },
    disable = function() {
      private$disabled <- TRUE
    },
    enable = function() {
      private$disabled <- FALSE
    },
    is_enabled = function() {
      !private$disabled
    },
    set_request_body = function(request_body) {
      if (typeof(request_body) == "list") {
        request_body <- jsonlite::toJSON(request_body, auto_unbox = TRUE) |> as.character()
      }
      private$request_body <- request_body
    },
    set_response_body = function(response_body) {
      if (typeof(response_body) == "list") {
        response_body <- jsonlite::toJSON(response_body, auto_unbox = TRUE) |> as.character()
      }
      private$response_body <- response_body
    },
    set_event_type = function(event_type) {
      private$event_type <- event_type
    },
    set_study_id = function(study_id) {
      private$study_id <- study_id
    },
    set_response_code = function(response_code) {
      private$response_code <- response_code
    },
    validate_log = function() {
      if (private$disabled) {
        stop("Audit log is disabled")
      }
      if (is.null(private$event_type)) {
        stop("Event type not set for audit log. Please set the event type using `audit_log_event_type`")
      }
    },
    persist = function() {
      if (private$disabled) {
        return()
      }
      db_conn <- pool::localCheckout(db_connection_pool)
      values <- list(
        private$request_id,
        private$event_type,
        private$study_id,
        private$endpoint_url,
        private$request_method,
        private$request_body,
        private$response_code,
        private$response_body
      )

      values <- purrr::map(values, \(x) ifelse(is.null(x), NA, x))

      DBI::dbGetQuery(
        db_conn,
        "INSERT INTO audit_log (
          request_id,
          event_type,
          study_id,
          endpoint_url,
          request_method,
          request_body,
          response_code,
          response_body
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)",
        values
      )
    }
  ),
  private = list(
    disabled = FALSE,
    request_id = NULL,
    event_type = NULL,
    study_id = NULL,
    endpoint_url = NULL,
    request_method = NULL,
    response_code = NULL,
    request_body = NULL,
    response_body = NULL
  )
)


#' Set up audit trail
#'
#' This function sets up an audit trail for a given process. It uses plumber's hooks to log
#' information before routing (preroute) and after serializing the response (postserialize).
#'
#' This function modifies the plumber router in place and returns the updated router.
#'
#' The audit trail is only enabled if the AUDIT_LOG_ENABLED environment variable is set to "true".
#'
#' @param pr A plumber router for which the audit trail is to be set up.
#' @param endpoints A list of regex patterns for which the audit trail should be enabled.
#' @return Returns the updated plumber router with the audit trail hooks.
#' @examples
#' pr <- plumber::plumb("your-api-definition.R") |>
#'   setup_audit_trail()
setup_audit_trail <- function(pr, endpoints) {
  audit_log_enabled <- Sys.getenv("AUDIT_LOG_ENABLED", "true") |> as.logical()
  if (!audit_log_enabled) {
    print("Audit log is disabled")
    return(pr)
  }
  print("Audit log is enabled")
  is_enabled_for_request <- function(req) {
    if (is.null(endpoints)) {
      return(TRUE)
    }
    any(sapply(endpoints, \(endpoint) grepl(endpoint, req$PATH_INFO)))
  }

  hooks <- list(
    preroute = function(req, res) {
      with_err_handler({
        if (!is_enabled_for_request(req)) {
          return()
        }
        audit_log <- AuditLog$new(
          request_method = req$REQUEST_METHOD,
          endpoint_url = req$PATH_INFO,
          request_body = req$body
        )
        req$.internal.audit_log <- audit_log
      })
    },
    postserialize = function(req, res) {
      with_err_handler({
        audit_log <- req$.internal.audit_log
        if (is.null(audit_log) || !audit_log$is_enabled()) {
          return()
        }
        audit_log$validate_log()
        audit_log$set_response_code(res$status)
        audit_log$set_request_body(req$body)
        audit_log$set_response_body(res$body)
        audit_log$persist()
      })
    }
  )
  pr |>
    plumber::pr_hooks(hooks)
}

#' Set Audit Log Event Type
#'
#' This function sets the event type for an audit log. It retrieves the audit log from the request's
#' internal data, and then calls the audit log's set_event_type method with the provided event type.
#'
#' @param event_type The event type to be set for the audit log.
#' @param req The request object, which should contain an audit log in its internal data.
#' @return Returns nothing as it modifies the audit log in-place.
audit_log_event_type <- function(event_type, req) {
  audit_log <- req$.internal.audit_log
  if (!is.null(audit_log)) {
    audit_log$set_event_type(event_type)
  }
}

#' Set Audit Log Study ID
#'
#' This function sets the study ID for an audit log. It retrieves the audit log from the request's
#' internal data, and then calls the audit log's set_study_id method with the provided study ID.
#'
#' @param study_id The study ID to be set for the audit log.
#' @param req The request object, which should contain an audit log in its internal data.
#' @return Returns nothing as it modifies the audit log in-place.
audit_log_study_id <- function(study_id, req) {
  assert(!is.null(study_id) || is.numeric(study_id), "Study ID must be a number")
  audit_log <- req$.internal.audit_log
  if (!is.null(audit_log)) {
    audit_log$set_study_id(study_id)
  }
}

audit_log_disable_for_request <- function(req) {
  audit_log <- req$.internal.audit_log
  if (!is.null(audit_log)) {
    audit_log$disable()
  }
}
