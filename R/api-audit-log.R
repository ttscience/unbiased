api_get_audit_log <- function(study_id, req, res) {
  audit_log_disable_for_request(req)

  if (!check_study_exist(study_id = study_id)) {
    res$status <- 404
    return(
      list(error = "Study not found")
    )
  }

  # Get audit trial
  audit_trail <- dplyr::tbl(db_connection_pool, "audit_log") |>
    dplyr::filter(study_id == !!study_id) |>
    dplyr::collect()

  audit_trail$request_body <- purrr::map(
    audit_trail$request_body,
    \(x) jsonlite::fromJSON(x)
  )
  audit_trail$response_body <- purrr::map(
    audit_trail$response_body,
    \(x) jsonlite::fromJSON(x)
  )

  return(audit_trail)
}
