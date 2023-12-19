skip_if_not(is_CI(), "DB tests require complex setup through Docker Compose")

test_that("there's a study named 'Badanie testowe' in 'study' table", {
  expect_contains(
    tbl(conn, "study") |>
      pull(name),
    "Badanie testowe"
  )
})

test_that("study named 'Badanie testowe' has an identifier 'TEST'", {
  expect_identical(
    tbl(conn, "study") |>
      filter(name == "Badanie testowe") |>
      pull(identifier),
    "TEST"
  )
})

test_that("it is enough to provide a name, an identifier, and a method id", {
  expect_no_error({
    tbl(conn, "study") |>
      rows_append(
        tibble(
          identifier = "FINE",
          name = "Correctly working study",
          method_id = 1
        ),
        copy = TRUE, in_place = TRUE
      )
  })
})

new_study_id <- tbl(conn, "study") |>
  filter(identifier == "FINE") |>
  pull(id)

test_that("can't insert a study that references a non-existing method", {
  expect_error({
    tbl(conn, "study") |>
      rows_append(
        tibble(
          identifier = "error",
          name = "Exception-throwing study",
          method_id = 28
        ),
        copy = TRUE, in_place = TRUE
      )
  }, regexp = "violates foreign key constraint")
})

test_that("deleting archivizes a study", {
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
      select(-parameters, -sys_period) |>
      collect(),
    tibble(
      id = new_study_id,
      identifier = "FINE",
      name = "Correctly working study",
      method_id = 1L
    )
  )
})

test_that("can't push arm with negative ratio", {
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

  added_petient_id <- return$id

  expect_error({
    tbl(conn, "patient_stratum") |>
      rows_append(
        tibble(patient_id = added_petient_id,
               stratum_id = 1,
               fct_value = "Female"),
        copy = TRUE, in_place = TRUE
      )
  }, regexp = "Factor value not specified as allowed")

  # add legal value
  expect_no_error({
    tbl(conn, "patient_stratum") |>
      rows_append(
        tibble(patient_id = added_petient_id,
               stratum_id = 1,
               fct_value = "F"),
        copy = TRUE, in_place = TRUE
      )
  })
})

test_that("numerical constraints are enforced", {
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

  expect_no_error({
    tbl(conn, "patient_stratum") |>
      rows_append(
        tibble(patient_id = added_petient_id,
               stratum_id = added_stratum_id,
               num_value = 23),
        copy = TRUE, in_place = TRUE
      )
  })

  # but you cannot add two values for one patient one stratum
  expect_error({
    tbl(conn, "patient_stratum") |>
      rows_append(
        tibble(patient_id = added_petient_id,
               stratum_id = added_stratum_id,
               num_value = 24),
        copy = TRUE, in_place = TRUE
      )
  }, regexp = "duplicate key value violates unique constraint")

  expect_no_error({
    tbl(conn, "patient_stratum") |>
    rows_delete(
      tibble(patient_id = added_petient_id,
             stratum_id = added_stratum_id),
      copy = TRUE, unmatched = "ignore"
    )
  })

  # and you can't add an illegal value
  expect_error({
    tbl(conn, "patient_stratum") |>
      rows_append(
        tibble(patient_id = added_petient_id,
               stratum_id = added_stratum_id,
               num_value = 16),
        copy = TRUE, in_place = TRUE
      )
  }, regexp = "New value is lower than minimum")
})
