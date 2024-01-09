#' Define study
#'
#' @description
#' Creates a study with specified parameters and publishes it to the DB.
#'
#' @param name `character(1)`\cr
#'  Full study name.
#' @param identifier `character(1)`\cr
#'  Study code, at most 12 characters.
#' @param arms `character()`\cr
#'  Arm names to use.
#' @param method `character(1)`\cr
#'  Randomization method to apply.
#' @param ratio `integer()`\cr
#'  Arm ratios, must be positive and the same length as arm names.
#' @param strata `list()`\cr
#'  List of character vectors, each list element being a stratum and each string
#'  being a possible stratum value. Could possibly take a numeric structure as
#'  well instead of a character vector, e.g. `list(min = 1, max = 10)`. It just
#'  needs handling by checking whether the inner list is named or not, I'd say.
#' @param parameters `list()`\cr
#'  Parameters to pass to randomization.
#'
#' @return This function is called for the side effect of updating the DB.
#'
#' @examples
#' \dontrun{
#' define_study(
#'   "DEMO", "Demonstrational study", c("placebo", "active"),
#'   method = "simple",
#'   strata = list(gender = c("F", "M"), working = c("yes", "no"))
#' )
#' }
#'
#' @export
define_study <- function(name, identifier, arms,
                         method = c("simple", "block"),
                         strata = list(),
                         parameters = NULL,
                         ratio = rep(1, times = length(arms))) {
  method <- match.arg(method)

  # Assertions
  assert_string(name)
  assert_string(identifier, max.chars = 12)

  assert_character(
    arms, min.chars = 1, any.missing = FALSE, min.len = 2, unique = TRUE
  )
  assert_integerish(ratio, lower = 0, any.missing = FALSE, len = length(arms))

  assert_list(strata, names = "unique", any.missing = FALSE)
  purrr::walk(strata, function(stratum) {
    # TODO: when allowing numeric strata, change the assertions here
    assert_character(
      stratum, min.chars = 1, any.missing = FALSE, min.len = 2, unique = TRUE
    )
  })

  assert_list(parameters, names = "unique", null.ok = TRUE)

  conn_from_pool <- pool::localCheckout(db_connection_pool)

  method_id <- tbl(conn_from_pool, "method") |>
    filter(name == !!method) |>
    pull(id)
  assert_int(method_id)

  # Actual code
  study_id <- tbl(conn_from_pool, "study") |>
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
    tbl(conn_from_pool, "arm") |>
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
      stratum_id <- tbl(conn_from_pool, "stratum") |>
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
      stratum_id <- tbl(conn_from_pool, "stratum") |>
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
        tbl(conn_from_pool, "factor_constraint") |>
          rows_append(
            tibble(
              stratum_id = stratum_id,
              value = as.character(value)
            ),
            copy = TRUE, in_place = TRUE
          )
      })
    }
  })

  study_id
}
