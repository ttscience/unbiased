source("./test-helpers.R")

test_that("it is enough to provide a name, an identifier, and a method id", {
  with_db_fixtures("fixtures/example_study.yml")
  expect_no_error({
    tbl(conn, "study") |>
      rows_append(
        tibble(
          identifier = "FINE",
          name = "Correctly working study",
          method = "minimisation_pocock"
        ),
        copy = TRUE, in_place = TRUE
      )
  })
})

# first study id is 1
new_study_id <- 1 |> as.integer()

test_that("deleting archivizes a study", {
  with_db_fixtures("fixtures/example_study.yml")
  expect_no_error({
    tbl(conn, "study") |>
      rows_delete(
        tibble(id = new_study_id),
        copy = TRUE, in_place = TRUE, unmatched = "ignore"
      )
  })

  expect_identical(
    tbl(conn, "study_history") |>
      filter(id == new_study_id) |>
      select(-parameters, -sys_period, -timestamp) |>
      collect(),
    tibble(
      id = new_study_id,
      identifier = "TEST",
      name = "Test Study",
      method = "minimisation_pocock"
    )
  )
})

test_that("can't push arm with negative ratio", {
  with_db_fixtures("fixtures/example_study.yml")
  expect_error({
    tbl(conn, "arm") |>
      rows_append(
        tibble(
          study_id = 1,
          name = "Exception-throwing arm",
          ratio = -1
        ),
        copy = TRUE, in_place = TRUE
      )
  }, regexp = "violates check constraint")
})

test_that("can't push stratum other than factor or numeric", {
  with_db_fixtures("fixtures/example_study.yml")
  expect_error({
    tbl(conn, "stratum") |>
      rows_append(
        tibble(
          study_id = 1,
          name = "failing stratum",
          value_type = "array"
        ),
        copy = TRUE, in_place = TRUE
      )
  }, regexp = "violates check constraint")
})

test_that("can't push stratum level outside of defined levels", {
  with_db_fixtures("fixtures/example_study.yml")
  # create a new patient
  return <-
    expect_no_error({
    tbl(conn, "patient") |>
      rows_append(
        tibble(study_id = 1,
               arm_id = 1,
               used = TRUE),
        copy = TRUE, in_place = TRUE, returning = id
      ) |>
      dbplyr::get_returned_rows()
  })

  added_patient_id <- return$id

  expect_error({
    tbl(conn, "patient_stratum") |>
      rows_append(
        tibble(patient_id = added_patient_id,
               stratum_id = 1,
               fct_value = "Female"),
        copy = TRUE, in_place = TRUE
      )
  }, regexp = "Factor value not specified as allowed")

  # add legal value
  expect_no_error({
    tbl(conn, "patient_stratum") |>
      rows_append(
        tibble(patient_id = added_patient_id,
               stratum_id = 1,
               fct_value = "F"),
        copy = TRUE, in_place = TRUE
      )
  })
})

test_that("numerical constraints are enforced", {
  with_db_fixtures("fixtures/example_study.yml")
  added_patient_id <- 1 |> as.integer()
  return <-
    expect_no_error({
      tbl(conn, "stratum") |>
        rows_append(
          tibble(study_id = 1,
                 name = "age",
                 value_type = "numeric"),
          copy = TRUE, in_place = TRUE, returning = id
        ) |>
        dbplyr::get_returned_rows()
    })

  added_stratum_id <- return$id

  expect_no_error({
    tbl(conn, "numeric_constraint") |>
      rows_append(
        tibble(stratum_id = added_stratum_id,
               min_value = 18,
               max_value = 64),
        copy = TRUE, in_place = TRUE
      )
  })

  # and you can't add an illegal value
  expect_error({
    tbl(conn, "patient_stratum") |>
      rows_append(
        tibble(patient_id = added_patient_id,
               stratum_id = added_stratum_id,
               num_value = 16),
        copy = TRUE, in_place = TRUE
      )
  }, regexp = "New value is lower than minimum")

  # you can add valid value
  expect_no_error({
    tbl(conn, "patient_stratum") |>
      rows_append(
        tibble(patient_id = added_patient_id,
               stratum_id = added_stratum_id,
               num_value = 23),
        copy = TRUE, in_place = TRUE
      )
  })

  # but you cannot add two values for one patient one stratum
  expect_error({
    tbl(conn, "patient_stratum") |>
      rows_append(
        tibble(patient_id = added_patient_id,
               stratum_id = added_stratum_id,
               num_value = 24),
        copy = TRUE, in_place = TRUE
      )
  }, regexp = "duplicate key value violates unique constraint")
})
