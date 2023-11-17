read_study_details <- function(study_id) {
  study <- tbl(CONN, "study") |>
    filter(id == study_id) |>
    select(id, name, identifier, method_id, parameters) |>
    left_join(
      tbl(CONN, "method") |>
        select(id, method = name),
      join_by(method_id == id)
    ) |>
    select(-method_id) |>
    collect() |>
    mutate(parameters = list(jsonlite::fromJSON(parameters)))

  arms <- tbl(CONN, "arm") |>
    filter(study_id == study_id) |>
    select(name, ratio) |>
    collect()

  strata <- tbl(CONN, "stratum") |>
    filter(study_id == study_id) |>
    select(id, name, value_type) |>
    collect() |>
    mutate(values = list(read_stratum_values(id, value_type)), .by = id) |>
    select(-id)

  mutate(
    study,
    arms = list(arms),
    strata = list(strata)
  )
}

read_stratum_values <- function(stratum_id, value_type) {
  switch(
    value_type,
    "factor" = {
      tbl(CONN, "factor_constraint") |>
        filter(stratum_id == stratum_id) |>
        pull(value)
    },
    "numeric" = {
      tbl(CONN, "numeric_constraint") |>
        filter(stratum_id == stratum_id) |>
        select(min_value, max_value) |>
        collect()
    }
  )
}
