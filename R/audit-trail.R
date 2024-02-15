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
      private$request_body <- request_body
    },
    set_response_body = function(response_body) {
      private$response_body <- response_body
    },
    set_event_type = function(event_type) {
      private$event_type <- event_type
    },
    set_study_id = function(study_id) {
      private$study_id <- study_id
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
      print("[Audit log begins here]")
      print(glue::glue("Request ID: {private$request_id}"))
      print(glue::glue("Event type: {private$event_type}"))
      print(glue::glue("Study ID: {private$study_id}"))
      print(glue::glue("Endpoint URL: {private$endpoint_url}"))
      print(glue::glue("Request Method: {private$request_method}"))
      print(glue::glue("Request Body: {private$request_body}"))
      print(glue::glue("Response Body: {private$response_body}"))
      print("[Audit log ends here]")
    }
  ),
  private = list(
    disabled = FALSE,
    request_id = NULL,
    event_type = NULL,
    study_id = NULL,
    endpoint_url = NULL,
    request_method = NULL,
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
#' @return Returns the updated plumber router with the audit trail hooks.
#' @examples
#' pr <- plumber::plumb("your-api-definition.R") |>
#'    setup_audit_trail()
setup_audit_trail <- function(pr) {
  audit_log_enabled <- Sys.getenv("AUDIT_LOG_ENABLED", "true") |> as.logical()
  if (!audit_log_enabled) {
    print("Audit log is disabled")
    return(pr)
  }
  print("Audit log is enabled")
  pr |>
    plumber::pr_hooks(list(
      preroute = function(req, res) {
        audit_log <- AuditLog$new(
          request_method = req$REQUEST_METHOD,
          endpoint_url = req$PATH_INFO,
          request_body = req$body
        )
        req$.internal.audit_log <- audit_log
      },
      postserialize = function(req, res) {
        audit_log <- req$.internal.audit_log
        if (!audit_log$is_enabled()) {
          return()
        }
        audit_log$validate_log()
        audit_log$set_request_body(req$body)
        audit_log$set_response_body(res$body)
        audit_log$persist()
      }
    ))
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