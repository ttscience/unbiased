skip_if_not(is_CI(), "DB tests require complex setup through Docker Compose")

# Define connection ----
conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  dbname = "postgres",
  host = "postgres",
  port = 5432,
  user = "postgres",
  password = "postgres"
)

on.exit({
  DBI::dbDisconnect(conn)
})

# Setup constants ----
versioned_tables <- c(
  "method", "study", "arm", "stratum", "factor_constraint",
  "numeric_constraint", "patient", "patient_stratum"
)
nonversioned_tables <- c("settings")

# Test values ----
test_that("database contains base tables", {
  expect_contains(
    DBI::dbListTables(conn),
    c(versioned_tables, nonversioned_tables)
  )
})

test_that("database contains history tables", {
  expect_contains(
    DBI::dbListTables(conn),
    glue::glue("{versioned_tables}_history")
  )
})
