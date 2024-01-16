#' Defines methods for interacting with the study in the database

get_similar_studies <- function(name, identifier) {
  similar <-
    dplyr::tbl(db_connection_pool, "study") |>
    dplyr::select(id, name, identifier) |>
    dplyr::filter(name == !!name | identifier == !!identifier) |>
    dplyr::collect()
  similar
}

create_study <- function(
    name, identifier, method, parameters, arms, strata) {
  connection <- pool::poolCheckout(db_connection_pool)

  r <- tryCatch(
    {
      DBI::dbBegin(connection)
      study_record <- list(
        name = name,
        identifier = identifier,
        method = method,
        parameters = jsonlite::toJSON(parameters, auto_unbox = TRUE)
        |> as.character()
      )

      study <- DBI::dbGetQuery(
        connection,
        "INSERT INTO study (name, identifier, method, parameters)
                    VALUES ($1, $2, $3, $4)
                    RETURNING id, name, identifier, method, parameters",
        unname(study_record)
      )

      study <- as.list(study)
      study$parameters <- jsonlite::fromJSON(study$parameters)

      arm_records <- arms |>
        purrr::imap(\(x, name) list(name=name, ratio=x)) |>
        purrr::map(tibble::as_tibble) |>
        purrr::list_c()
      arm_records$study_id <- study$id

      DBI::dbWriteTable(
        connection,
        "arm",
        arm_records,
        append = TRUE,
        row.names = FALSE
      )

      created_arms <- DBI::dbGetQuery(
        connection,
        "SELECT id, study_id, name, ratio
                    FROM arm
                    WHERE study_id = $1",
        study$id
      )

      study$arms <- created_arms

      stratum_records <- strata |>
        purrr::imap(\(x, name) list(name = name, value_type = x$value_type)) |>
        purrr::map(tibble::as_tibble) |>
        purrr::list_c()
      stratum_records$study_id <- study$id

      DBI::dbWriteTable(
        connection,
        "stratum",
        stratum_records,
        append = TRUE,
        row.names = FALSE
      )

      created_strata <- DBI::dbGetQuery(
        connection,
        "SELECT id, study_id, name, value_type
                    FROM stratum
                    WHERE study_id = $1",
        study$id
      )

      factor_constraints <- strata |>
        purrr::imap(\(x, name) tibble::as_tibble(x)) |>
        purrr::list_c() |>
        dplyr::filter(.data$value_type == "factor") |>
        dplyr::select(name, levels) |>
        dplyr::left_join(created_strata, dplyr::join_by("name")) |>
        dplyr::select(id, levels) |>
        dplyr::rename(value = levels, stratum_id = id)

      DBI::dbWriteTable(
        connection,
        "factor_constraint",
        factor_constraints,
        append = TRUE,
        row.names = FALSE
      )

      DBI::dbCommit(connection)
      list(study = study)
    },
    error = function(cond) {
      logger::log_error("Error creating study: {cond}", cond=cond)
      DBI::dbRollback(connection)
      list(error = conditionMessage(cond))
    }
  )

  r
}

save_patient <- function(study_id, arm_id){
  randomized_patient <- DBI::dbGetQuery(
    db_connection_pool,
    "INSERT INTO patient (arm_id, study_id)
                    VALUES ($1, $2)
                    RETURNING id, arm_id",
    list(arm_id, study_id)
  )

  return(randomized_patient)
}

