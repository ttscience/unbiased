# Named with '0' to make sure that this one runs first because it validates
# basic properties of the database

source("./test-helpers.R")

# Setup constants ----


# Test values ----
test_that("database contains base tables", {
  conn <- pool::localCheckout(
    get("db_connection_pool", envir = globalenv())
  )
  with_db_fixtures("fixtures/example_study.yml")
  expect_contains(
    DBI::dbListTables(conn),
    c(versioned_tables, nonversioned_tables)
  )
})

test_that("database contains history tables", {
  conn <- pool::localCheckout(
    get("db_connection_pool", envir = globalenv())
  )
  with_db_fixtures("fixtures/example_study.yml")
  expect_contains(
    DBI::dbListTables(conn),
    glue::glue("{versioned_tables}_history")
  )
})
