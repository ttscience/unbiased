#' Utility functions for validation

append_error <- function(validation_errors, field, error) {
  if (field %in% names(validation_errors)) {
    validation_errors[[field]] <- c(validation_errors[[field]], error)
  } else {
    validation_errors[[field]] <- list(error)
  }
  return(validation_errors)
}

ValidationErrors <- R6::R6Class("ValidationErrors",
  public = list(
    initialize = function() {
      private$errors <- list()
    },
    validate_field = function(field_name, ...) {
      errors <- list(...)
      for (error in errors) {
        if (error != TRUE) {
          private$ensure_field_exists(field_name)
          private$append_field_error(field_name, error)
        }
      }
      invisible(self)
    },
    has_errors = function() {
      return(length(private$errors) > 0)
    },
    get_errors = function() {
      return(private$errors)
    }
  ),
  private = list(
    errors = NULL,
    ensure_field_exists = function(field_name) {
      if (!(field_name %in% names(private$errors))) {
        private$errors[[field_name]] <- list()
      }
    },
    append_field_error = function(field_name, error) {
      private$ensure_field_exists(field_name)

      private$errors[[field_name]] <- c(private$errors[[field_name]], error)
    }
  )
)
