list_studies <- function() {
  tbl(CONN, "study") |>
    select(id, identifier, name, timestamp) |>
    arrange(desc(timestamp)) |>
    collect()
}

study_exists <- function(study_id) {
  row_id <- tbl(CONN, "study") |>
    filter(id == !!study_id) |>
    pull(id)
  test_int(row_id)
}
