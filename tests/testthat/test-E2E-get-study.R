test_that("correct request to reads studies with the structure of the returned result", {
  source("./test-helpers.R")

  conn <- pool::localCheckout(
    get("db_connection_pool", envir = globalenv())
  )
  with_db_fixtures("fixtures/example_study.yml")

  response <- request(api_url) |>
    req_url_path("study", "") |>
    req_method("GET") |>
    req_perform()

  response_body <-
    response |>
    resp_body_json()

  testthat::expect_equal(response$status_code, 200)

  checkmate::expect_names(
    names(response_body[[1]]),
    identical.to = c("study_id", "identifier", "name", "method", "last_edited")
  )

  checkmate::expect_list(
    response_body[[1]],
    any.missing = TRUE,
    null.ok = FALSE,
    len = 5,
    type = c("numeric", "character", "character", "character", "character")
  )

  # Compliance of the number of tests

  n_studies <-
    dplyr::tbl(db_connection_pool, "study") |>
    collect() |>
    nrow()

  testthat::expect_equal(length(response_body), n_studies)
})

test_that("correct request to reads records for chosen study_id with the structure of the returned result", {
  response <- request(api_url) |>
    req_url_path("study", "minimisation_pocock") |>
    req_method("POST") |>
    req_body_json(
      data = list(
        identifier = "ABC-X",
        name = "Study ABC-X",
        method = "var",
        p = 0.85,
        arms = list(
          "placebo" = 1,
          "active" = 1
        ),
        covariates = list(
          sex = list(
            weight = 1,
            levels = c("female", "male")
          ),
          weight = list(
            weight = 1,
            levels = c("up to 60kg", "61-80 kg", "81 kg or more")
          )
        )
      )
    ) |>
    req_perform()

  response_body <-
    response |>
    resp_body_json()

  response_study <-
    request(api_url) |>
    req_url_path("study", response_body$study$id) |>
    req_method("GET") |>
    req_perform()

  response_study_body <-
    response_study |>
    resp_body_json()

  testthat::expect_equal(response$status_code, 200)

  checkmate::expect_names(
    names(response_study_body),
    identical.to = c("study_id", "name", "randomization_method", "last_edited", "p", "method", "strata", "arms")
  )

  checkmate::expect_list(
    response_study_body,
    any.missing = TRUE,
    null.ok = TRUE,
    len = 8,
    type = c("numeric", "character", "character", "character", "numeric", "character", "list", "character")
  )

  response_study_id <-
    tryCatch(
      {
        request(api_url) |>
          req_url_path("study", response_body$study$id + 1) |>
          req_method("GET") |>
          req_perform()
      },
      error = function(e) e
    )

  testthat::expect_equal(response_study_id$status, 404)
})
