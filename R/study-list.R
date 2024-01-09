#' List available studies
#'
#' @description
#' Queries the DB for the basic information about existing studies.
#'
#' @return A tibble with basic study info, including ID.
#'
#' @export
list_studies <- function() {
  tbl(db_connection_pool, "study") |>
    select(id, identifier, name, timestamp) |>
    arrange(desc(timestamp)) |>
    collect()
}

#' Validate study existence
#'
#' @description
#' Checks the database for the existence of given ID.
#'
#' @param study_id `integer(1)`\cr
#'  ID of the study.
#'
#' @return `TRUE` or `FALSE`, depending whether given ID exists in the DB.
#'
#' @export
study_exists <- function(study_id) {
  row_id <- tbl(db_connection_pool, "study") |>
    filter(id == !!study_id) |>
    pull(id)
  test_int(row_id)
}
