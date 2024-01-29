
versioned_tables <- c(
  "study", "arm", "stratum", "factor_constraint",
  "numeric_constraint", "patient", "patient_stratum"
)
nonversioned_tables <- c()

all_tables <- c(
  versioned_tables,
  nonversioned_tables,
  versioned_tables |> paste0("_history")
)

with_db_fixtures <- function(test_data_path, env = parent.frame()) {
  conn <- get("conn", envir = .GlobalEnv)

  # load test data in yaml format
  test_data <- yaml::read_yaml(test_data_path)

  # truncate tables before inserting data
  truncate_tables(all_tables)

  for (table_name in names(test_data)) {
    # get table data
    table_data <- test_data[table_name] |> dplyr::bind_rows()

    DBI::dbWriteTable(
      conn,
      table_name,
      table_data,
      append = TRUE,
      row.names = FALSE
    )
  }

  withr::defer(
    {
      truncate_tables(all_tables)
    },
    env
  )
}

truncate_tables <- function(tables) {
  DBI::dbExecute(
    "SET client_min_messages TO WARNING;",
    conn = get("conn", envir = .GlobalEnv)
  )
  tables |>
    rev() |>
    purrr::walk(
      \(table_name) {
        glue::glue_sql(
          "TRUNCATE TABLE {`table_name`} RESTART IDENTITY CASCADE;",
          .con = get("conn", envir = .GlobalEnv)
        ) |> DBI::dbExecute(conn = get("conn", envir = .GlobalEnv))
      }
    )
}