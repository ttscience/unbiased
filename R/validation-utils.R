#' Utility functions for validation

append_error <- function(validation_errors, field, error) {
  if (field %in% names(validation_errors)) {
    validation_errors[[field]] <- c(validation_errors[[field]], error)
  } else {
    validation_errors[[field]] <- list(error)
  }
  return(validation_errors)
}
