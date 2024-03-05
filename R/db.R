#' Defines methods for interacting with the study in the database

#' Create a database connection pool
#'
#' This function creates a connection pool to a PostgreSQL database. It uses
#' environment variables to get the necessary connection parameters. If the
#' connection fails, it will retry up to 5 times with a delay of 2 seconds
#' between each attempt.
#'
#' @return A pool object representing the connection pool to the database.
#' @export
#'
#' @examples
#' \dontrun{
#' pool <- create_db_connection_pool()
#' }
create_db_connection_pool <- purrr::insistently(function() {
  dbname <- Sys.getenv("POSTGRES_DB")
  host <- Sys.getenv("POSTGRES_HOST")
  port <- Sys.getenv("POSTGRES_PORT", 5432)
  user <- Sys.getenv("POSTGRES_USER")
  password <- Sys.getenv("POSTGRES_PASSWORD")
  print(
    glue::glue("Creating database connection pool to {dbname} at {host}:{port} as {user}")
  )
  pool::dbPool(
    RPostgres::Postgres(),
    dbname = dbname,
    host = host,
    port = port,
    user = user,
    password = password
  )
}, rate = purrr::rate_delay(1, max_times = 15), quiet = FALSE)


get_similar_studies <- function(name, identifier) {
  db_connection_pool <- get("db_connection_pool")
  similar <-
    dplyr::tbl(db_connection_pool, "study") |>
    dplyr::select(id, name, identifier) |>
    dplyr::filter(name == !!name | identifier == !!identifier) |>
    dplyr::collect()
  similar
}

check_study_exist <- function(study_id) {
  db_connection_pool <- get("db_connection_pool")
  study_exists <- dplyr::tbl(db_connection_pool, "study") |>
    dplyr::filter(id == !!study_id) |>
    dplyr::collect() |>
    nrow() > 0
  study_exists
}

create_study <- function(
    name, identifier, method, parameters, arms, strata) {
  db_connection_pool <- get("db_connection_pool", envir = .GlobalEnv)
  connection <- pool::localCheckout(db_connection_pool)

  DBI::dbWithTransaction(
    connection,
    {
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
        purrr::imap(\(x, name) list(name = name, ratio = x)) |>
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

      list(study = study)
    }
  )
}

save_patient <- function(study_id, arm_id, used) {
  DBI::dbGetQuery(
    db_connection_pool,
    "INSERT INTO patient (arm_id, study_id, used)
                VALUES ($1, $2, $3)
                RETURNING id, arm_id, used",
    list(arm_id, study_id, used)
  )
}
