source("./test-helpers.R")

pool <- get("db_connection_pool", envir = globalenv())

test_that("it is enough to provide a name, an identifier, and a method id", {
  conn <- pool::localCheckout(pool)
  with_db_fixtures("fixtures/example_db.yml")
  testthat::expect_no_error({
    dplyr::tbl(conn, "study") |>
      dplyr::rows_append(
        tibble::tibble(
          identifier = "FINE",
          name = "Correctly working study",
          method = "minimisation_pocock"
        ),
        copy = TRUE, in_place = TRUE
      )
  })
})

# first study id is 1
new_study_id <- as.integer(1)

test_that("deleting archivizes a study", {
  conn <- pool::localCheckout(pool)
  with_db_fixtures("fixtures/example_db.yml")
  testthat::expect_no_error({
    dplyr::tbl(conn, "study") |>
      dplyr::rows_delete(
        tibble::tibble(id = new_study_id),
        copy = TRUE, in_place = TRUE, unmatched = "ignore"
      )
  })

  testthat::expect_identical(
    dplyr::tbl(conn, "study_history") |>
      dplyr::filter(id == new_study_id) |>
      dplyr::select(-parameters, -sys_period, -timestamp) |>
      dplyr::collect(),
    tibble::tibble(
      id = new_study_id,
      identifier = "TEST",
      name = "Test Study",
      method = "minimisation_pocock"
    )
  )
})

test_that("can't push arm with negative ratio", {
  conn <- pool::localCheckout(pool)
  with_db_fixtures("fixtures/example_db.yml")
  testthat::expect_error(
    {
      dplyr::tbl(conn, "arm") |>
        dplyr::rows_append(
          tibble::tibble(
            study_id = 1,
            name = "Exception-throwing arm",
            ratio = -1
          ),
          copy = TRUE, in_place = TRUE
        )
    },
    regexp = "violates check constraint"
  )
})

test_that("can't push stratum other than factor or numeric", {
  conn <- pool::localCheckout(pool)
  with_db_fixtures("fixtures/example_db.yml")
  testthat::expect_error(
    {
      tbl(conn, "stratum") |>
        rows_append(
          tibble(
            study_id = 1,
            name = "failing stratum",
            value_type = "array"
          ),
          copy = TRUE, in_place = TRUE
        )
    },
    regexp = "violates check constraint"
  )
})

test_that("can't push stratum level outside of defined levels", {
  conn <- pool::localCheckout(pool)
  with_db_fixtures("fixtures/example_db.yml")
  # create a new patient
  return <-
    testthat::expect_no_error({
      dplyr::tbl(conn, "patient") |>
        dplyr::rows_append(
          tibble::tibble(
            study_id = 1,
            arm_id = 1,
            used = TRUE
          ),
          copy = TRUE, in_place = TRUE, returning = id
        ) |>
        dbplyr::get_returned_rows()
    })

  added_patient_id <- return$id

  testthat::expect_error(
    {
      dplyr::tbl(conn, "patient_stratum") |>
        dplyr::rows_append(
          tibble::tibble(
            patient_id = added_patient_id,
            stratum_id = 1,
            fct_value = "Female"
          ),
          copy = TRUE, in_place = TRUE
        )
    },
    regexp = "Factor value not specified as allowed"
  )

  # add legal value
  testthat::expect_no_error({
    dplyr::tbl(conn, "patient_stratum") |>
      dplyr::rows_append(
        tibble::tibble(
          patient_id = added_patient_id,
          stratum_id = 1,
          fct_value = "F"
        ),
        copy = TRUE, in_place = TRUE
      )
  })
})

test_that("numerical constraints are enforced", {
  conn <- pool::localCheckout(pool)
  with_db_fixtures("fixtures/example_db.yml")
  added_patient_id <- as.integer(1)
  return <-
    testthat::expect_no_error({
      dplyr::tbl(conn, "stratum") |>
        dplyr::rows_append(
          tibble::tibble(
            study_id = 1,
            name = "age",
            value_type = "numeric"
          ),
          copy = TRUE, in_place = TRUE, returning = id
        ) |>
        dbplyr::get_returned_rows()
    })

  added_stratum_id <- return$id

  testthat::expect_no_error({
    dplyr::tbl(conn, "numeric_constraint") |>
      dplyr::rows_append(
        tibble::tibble(
          stratum_id = added_stratum_id,
          min_value = 18,
          max_value = 64
        ),
        copy = TRUE, in_place = TRUE
      )
  })

  # and you can't add an illegal value
  testthat::expect_error(
    {
      dplyr::tbl(conn, "patient_stratum") |>
        dplyr::rows_append(
          tibble::tibble(
            patient_id = added_patient_id,
            stratum_id = added_stratum_id,
            num_value = 16
          ),
          copy = TRUE, in_place = TRUE
        )
    },
    regexp = "New value is lower than minimum"
  )

  # you can add valid value
  testthat::expect_no_error({
    dplyr::tbl(conn, "patient_stratum") |>
      dplyr::rows_append(
        dplyr::tibble(
          patient_id = added_patient_id,
          stratum_id = added_stratum_id,
          num_value = 23
        ),
        copy = TRUE, in_place = TRUE
      )
  })

  # but you cannot add two values for one patient one stratum
  testthat::expect_error(
    {
      dplyr::tbl(conn, "patient_stratum") |>
        dplyr::rows_append(
          tibble::tibble(
            patient_id = added_patient_id,
            stratum_id = added_stratum_id,
            num_value = 24
          ),
          copy = TRUE, in_place = TRUE
        )
    },
    regexp = "duplicate key value violates unique constraint"
  )
})
