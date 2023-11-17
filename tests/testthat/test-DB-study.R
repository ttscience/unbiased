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
  })
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
      select(-parameters, -sys_period, -timestamp) |>
      collect(),
    tibble(
      id = new_study_id,
      identifier = "FINE",
      name = "Correctly working study",
      method_id = 1L
    )
  )
})
