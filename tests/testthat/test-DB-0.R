# Named with '0' to make sure that this one runs first because it validates
# basic properties of the database
# skip_if_not(is_CI(), "DB tests require complex setup through Docker Compose")

source("./test-helpers.R")

# Setup constants ----


# Test values ----
test_that("database contains base tables", {
  with_db_fixtures("fixtures/example_study.yml")
  expect_contains(
    DBI::dbListTables(conn),
    c(versioned_tables, nonversioned_tables)
  )
})

test_that("database contains history tables", {
  with_db_fixtures("fixtures/example_study.yml")
  expect_contains(
    DBI::dbListTables(conn),
    glue::glue("{versioned_tables}_history")
  )
})
