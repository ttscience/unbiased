#' Read study details
#'
#' @description
#' Queries the DB for the study parameters, including declared arms and strata.
#'
#' @param study_id `integer(1)`\cr
#'  ID of the study.
#'
#' @return A tibble with study details, containing potentially complex columns,
#' like `arms`.
#'
#' @export
read_study_details <- function(study_id) {
  arms <- tbl(db_connection_pool, "arm") |>
    filter(study_id == !!study_id) |>
    select(name, ratio) |>
    collect()

  strata <- tbl(db_connection_pool, "stratum") |>
    filter(study_id == !!study_id) |>
    select(id, name, value_type) |>
    collect() |>
    mutate(values = list(read_stratum_values(id, value_type)), .by = id) |>
    select(-id)

  tbl(db_connection_pool, "study") |>
    filter(id == !!study_id) |>
    select(id, name, identifier, method_id, parameters) |>
    left_join(
      tbl(db_connection_pool, "method") |>
        select(id, method = name),
      join_by(method_id == id)
    ) |>
    select(-method_id) |>
    collect() |>
    mutate(
      parameters = list(jsonlite::fromJSON(parameters)),
      arms = list(arms),
      strata = list(strata)
    )
}

read_stratum_values <- function(stratum_id, value_type) {
  switch(
    value_type,
    "factor" = {
      tbl(db_connection_pool, "factor_constraint") |>
        filter(stratum_id == !!stratum_id) |>
        pull(value)
    },
    "numeric" = {
      tbl(db_connection_pool, "numeric_constraint") |>
        filter(stratum_id == !!stratum_id) |>
        select(min_value, max_value) |>
        collect()
    }
  )
}
