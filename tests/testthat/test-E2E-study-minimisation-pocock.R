test_that("correct request with the structure of the returned result", {
  source("./test-helpers.R")
  source("./audit-log-test-helpers.R")
  with_db_fixtures("fixtures/example_db.yml")
  assert_audit_trail_for_test(c(
    "study_create",
    "randomize_patient"
  ))
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

  testthat::expect_equal(response$status_code, 200)
  checkmate::expect_number(response_body$study$id, lower = 1)

  response_patient <- request(api_url) |>
    req_url_path("study", response_body$study$id, "patient") |>
    req_method("POST") |>
    req_body_json(
      data = list(
        current_state =
          tibble::tibble(
            "sex" = c("female", "male"),
            "weight" = c("61-80 kg", "81 kg or more"),
            "arm" = c("placebo", "")
          )
      )
    ) |>
    req_perform()

  response_patient_body <-
    response_patient |>
    resp_body_json()

  testthat::expect_equal(response$status_code, 200)
  checkmate::expect_number(response_patient_body$patient_id, lower = 1)

  # Endpoint Response Structure Test
  checkmate::expect_names(
    names(response_patient_body),
    identical.to = c("patient_id", "arm_id", "arm_name")
  )

  checkmate::expect_list(
    response_patient_body,
    any.missing = TRUE,
    null.ok = FALSE,
    len = 3,
    type = c("numeric", "numeric", "character")
  )

  checkmate::test_true(
    dplyr::tbl(db_connection_pool, "patient") |>
      dplyr::slice_max(id) |>
      dplyr::collect() |>
      dplyr::pull(used),
    TRUE
  )
})

test_that("request with one covariate at two levels", {
  response_cov <-
    request(api_url) |>
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
          )
        )
      )
    ) |>
    req_perform()

  response_cov_body <-
    response_cov |>
    resp_body_json()

  testthat::expect_equal(response_cov$status_code, 200)
})

test_that("request with incorrect study id", {
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
    tryCatch(
      {
        request(api_url) |>
          req_url_path("study", response_body$study$id + 1, "patient") |>
          req_method("POST") |>
          req_body_json(
            data = list(
              current_state =
                tibble::tibble(
                  "sex" = c("female", "male"),
                  "weight" = c("61-80 kg", "81 kg or more"),
                  "arm" = c("placebo", "")
                )
            )
          ) |>
          req_perform()
      },
      error = function(e) e
    )

  testthat::expect_equal(response_study$status, 404, label = "HTTP status code")
})

test_that("request with patient that is assigned an arm at entry", {
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

  response_cs_arm <-
    tryCatch(
      {
        request(api_url) |>
          req_url_path("study", response_body$study$id, "patient") |>
          req_method("POST") |>
          req_body_json(
            data = list(
              current_state =
                tibble::tibble(
                  "sex" = c("female", "male"),
                  "weight" = c("61-80 kg", "81 kg or more"),
                  "arm" = c("placebo", "control")
                )
            )
          ) |>
          req_perform()
      },
      error = function(e) e
    )

  testthat::expect_equal(
    response_cs_arm$status, 400,
    label = "HTTP status code"
  )

  response_cs_records <-
    tryCatch(
      {
        request(api_url) |>
          req_url_path("study", response_body$study$id, "patient") |>
          req_method("POST") |>
          req_body_json(
            data = list(
              current_state =
                tibble::tibble(
                  "sex" = c("female"),
                  "weight" = c("61-80 kg"),
                  "arm" = c("placebo")
                )
            )
          ) |>
          req_perform()
      },
      error = function(e) e
    )

  testthat::expect_equal(
    response_cs_records$status, 400,
    label = "HTTP status code"
  )

  response_current_state <-
    tryCatch(
      {
        request(api_url) |>
          req_url_path("study", response_body$study$id, "patient") |>
          req_method("POST") |>
          req_body_json(
            data = list(
              current_state =
                tibble::tibble(
                  "sex" = c("female", "male"),
                  "weight" = c("61-80 kg", "81 kg or more")
                )
            )
          ) |>
          req_perform()
      },
      error = function(e) e
    )

  testthat::expect_equal(
    response_current_state$status, 400,
    label = "HTTP status code"
  )
})

test_that("request with incorrect number of levels", {
  response_cov <-
    tryCatch(
      {
        request(api_url) |>
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
                  levels = c("female")
                ),
                weight = list(
                  weight = 1,
                  levels = c("up to 60kg", "61-80 kg", "81 kg or more")
                )
              )
            )
          ) |>
          req_perform()
      },
      error = function(e) e
    )

  testthat::expect_equal(response_cov$status, 400)
})

test_that("request with incorrect parameter p", {
  response_p <-
    tryCatch(
      {
        request(api_url) |>
          req_url_path("study", "minimisation_pocock") |>
          req_method("POST") |>
          req_body_json(
            data = list(
              identifier = "ABC-X",
              name = "Study ABC-X",
              method = "var",
              p = "A",
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
      },
      error = function(e) e
    )

  testthat::expect_equal(response_p$status, 400)
})

test_that("request with incorrect arms", {
  response_arms <-
    tryCatch(
      {
        request(api_url) |>
          req_url_path("study", "minimisation_pocock") |>
          req_method("POST") |>
          req_body_raw('{
          "identifier": "ABC-X",
        "name": "Study ABC-X",
        "method": "var",
        "p": 0.85,
        "arms": {
          "placebo": 1,
          "placebo": 1
        },
        "covariates": {
          "sex": {
            "weight": 1,
            "levels": ["female", "male"]
          },
          "weight": {
            "weight": 1,
            "levels": ["up to 60kg", "61-80 kg", "81 kg or more"]
          }
        }
      }') |>
          req_perform()
      },
      error = function(e) e
    )

  testthat::expect_equal(response_arms$status, 400)
})

test_that("request with incorrect method", {
  response_method <-
    tryCatch(
      {
        request(api_url) |>
          req_url_path("study", "minimisation_pocock") |>
          req_method("POST") |>
          req_body_json(
            data = list(
              identifier = "ABC-X",
              name = "Study ABC-X",
              method = 1,
              p = 0.85,
              arms = list(
                "placebo" = 1,
                "control" = 1
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
      },
      error = function(e) e
    )

  testthat::expect_equal(response_method$status, 400)
})

test_that("request with incorrect weights", {
  response_weights <-
    tryCatch(
      {
        request(api_url) |>
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
                "control" = 1
              ),
              covariates = list(
                sex = list(
                  weight = "1",
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
      },
      error = function(e) e
    )

  testthat::expect_equal(response_weights$status, 400)
})

test_that("request with incorrect ratio", {
  response_ratio <-
    tryCatch(
      {
        request(api_url) |>
          req_url_path("study", "minimisation_pocock") |>
          req_method("POST") |>
          req_body_json(
            data = list(
              identifier = "ABC-X",
              name = "Study ABC-X",
              method = "var",
              p = 0.85,
              arms = list(
                "placebo" = "1",
                "control" = 1
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
      },
      error = function(e) e
    )

  testthat::expect_equal(response_ratio$status, 400)
})
