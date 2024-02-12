api_get_study <- function(res, req){
  db_connection_pool <- get("db_connection_pool")


  study_list <-
    dplyr::tbl(db_connection_pool, "study") |>
    dplyr::select(study_id = id, name, method, timestamp) |>
    dplyr::collect() |>
    tibble::as_tibble()

  return(study_list)
}
