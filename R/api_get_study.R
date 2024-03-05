api_get_study <- function(req, res) {
  audit_log_disable_for_request(req)
  db_connection_pool <- get("db_connection_pool")

  study_list <-
    dplyr::tbl(db_connection_pool, "study") |>
    dplyr::select(study_id = id, identifier, name, method, last_edited = timestamp) |>
    dplyr::collect() |>
    tibble::as_tibble()

  return(study_list)
}

api_get_study_records <- function(study_id, req, res) {
  audit_log_set_event_type("get_study_record", req)
  db_connection_pool <- get("db_connection_pool")

  study_id <- req$args$study_id

  if (!check_study_exist(study_id)) {
    res$status <- 404
    return(list(
      error = "Study not found"
    ))
  }
  audit_log_set_study_id(study_id, req)

  study <-
    dplyr::tbl(db_connection_pool, "study") |>
    dplyr::filter(id == !!study_id) |>
    dplyr::select(
      study_id = id, name, randomization_method = method,
      last_edited = timestamp, parameters
    ) |>
    dplyr::collect() |>
    tibble::remove_rownames()

  strata <-
    dplyr::tbl(db_connection_pool, "stratum") |>
    dplyr::filter(study_id == !!study_id) |>
    dplyr::select(stratum_id = id, stratum_name = name, value_type) |>
    collect() |>
    left_join(
      bind_rows(
        dplyr::tbl(db_connection_pool, "factor_constraint") |>
          dplyr::collect(),
        dplyr::tbl(db_connection_pool, "numeric_constraint") |>
          dplyr::collect()
      ),
      by = "stratum_id"
    ) |>
    tidyr::unite("value_num", c("min_value", "max_value"),
      sep = " - ", na.rm = TRUE
    ) |>
    dplyr::mutate(value = ifelse(is.na(value), value_num, value)) |>
    dplyr::select(stratum_name, value_type, value) |>
    left_join(
      study$parameters |>
        jsonlite::fromJSON() |>
        purrr::flatten_dfr() |>
        select(-c(p, method)) |>
        tidyr::pivot_longer(
          cols = everything(),
          names_to = "stratum_name",
          values_to = "weight"
        ),
      by = "stratum_name"
    ) |>
    group_by(stratum_name, value_type, weight) |>
    summarise(levels = list(value))

  arms <-
    dplyr::tbl(db_connection_pool, "arm") |>
    dplyr::filter(study_id == !!study_id) |>
    dplyr::select(arm_name = name, ratio) |>
    dplyr::collect() |>
    tidyr::pivot_wider(names_from = arm_name, values_from = ratio) |>
    as.list()

  study_elements <-
    list(
      strata = strata,
      arms = arms
    )

  study_list <- c(
    study |>
      dplyr::select(-parameters),
    study$parameters |>
      jsonlite::fromJSON() |>
      purrr::flatten_dfr() |>
      dplyr::select(p, method),
    study_elements
  )

  return(study_list)
}
