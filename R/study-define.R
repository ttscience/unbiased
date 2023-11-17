define_study <- function(name, identifier, method, arms,
                         strata = list(),
                         parameters = NULL,
                         ratio = rep(1, times = length(arms))) {
  # Assertions
  method_id <- tbl(CONN, "method") |>
    filter(name == !!method) |>
    pull(id)
  assert_int(method_id)

  assert_integerish(ratio, lower = 0, len = length(arms))

  # Actual code
  study_id <- tbl(CONN, "study") |>
    rows_append(
      tibble(
        identifier = identifier,
        name = name,
        method_id = method_id,
        parameters = jsonlite::toJSON(parameters, auto_unbox = FALSE)
      ),
      copy = TRUE, in_place = TRUE, returning = id
    ) |>
    dbplyr::get_returned_rows() |>
    pull(id)

  purrr::walk2(arms, ratio, function(arm, prop) {
    tbl(CONN, "arm") |>
      rows_append(
        tibble(
          study_id = study_id,
          name = arm,
          ratio = prop
        ),
        copy = TRUE, in_place = TRUE
      )
  })

  purrr::iwalk(strata, function(stratum, name) {
    if (is.numeric(stratum)) {
      # Numeric case
      stratum_id <- tbl(CONN, "stratum") |>
        rows_append(
          tibble(
            study_id = study_id,
            name = name,
            value_type = "numeric"
          ),
          copy = TRUE, in_place = TRUE, returning = id
        ) |>
        dbplyr::get_returned_rows() |>
        pull(id)

      # TODO: how to set min/max values?
    } else {
      # Factor case
      stratum_id <- tbl(CONN, "stratum") |>
        rows_append(
          tibble(
            study_id = study_id,
            name = name,
            value_type = "factor"
          ),
          copy = TRUE, in_place = TRUE, returning = id
        ) |>
        dbplyr::get_returned_rows() |>
        pull(id)

      purrr::walk(stratum, function(value) {
        tbl(CONN, "factor_constraint") |>
          rows_append(
            tibble(
              stratum_id = stratum_id,
              value = value
            ),
            copy = TRUE, in_place = TRUE
          )
      })
    }
  })
}
