# Named with '0' to make sure that this one runs first because it validates
# basic properties of the database
skip_if_not(is_CI(), "DB tests require complex setup through Docker Compose")

# Setup constants ----
versioned_tables <- c(
  "study", "arm", "stratum", "factor_constraint",
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

test_that("database version is the same as package version (did you update /inst/postgres/00-metadata.sql?)", {
  expect_identical(
    tbl(conn, "settings") |>
      filter(key == "schema_version") |>
      pull(value),
    packageVersion("unbiased") |>
      as.character()
  )
})
