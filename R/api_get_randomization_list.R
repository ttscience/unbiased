api_get_rand_list <- function(study_id, req, res) {
  audit_log_set_event_type("get_rand_list", req)
  db_connection_pool <- get("db_connection_pool")

  study_id <- req$args$study_id

  is_study <- check_study_exist(study_id = study_id)

  if (!is_study) {
    res$status <- 404
    return(list(
      error = "Study not found"
    ))
  }
  audit_log_set_study_id(study_id, req)

  patients <-
    dplyr::tbl(db_connection_pool, "patient") |>
    dplyr::filter(study_id == !!study_id) |>
    dplyr::left_join(
      dplyr::tbl(db_connection_pool, "arm") |>
        dplyr::select(arm_id = id, arm = name),
      by = "arm_id"
    ) |>
    dplyr::select(
      patient_id = id, arm, used, sys_period
    ) |>
    dplyr::collect() |>
    dplyr::mutate(sys_period = as.character(gsub("\\[\"|\\+00\",\\)", "", sys_period))) |>
    dplyr::mutate(sys_period = as.POSIXct(sys_period))

  return(patients)
}
