test_that("endpoint returns the study id, can randomize 2 patients", {
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
          "active" = 1),
        covariates = list(
          sex = list(
            weight = 1,
            levels = c("female", "male")
          ),
          weight = list(
            weight = 1,
            levels = c("up to 60kg", "61-80 kg", "81 kg or more")
          )
        ))
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
      data = list(current_state =
                    tibble::tibble("sex" = c("female", "male"),
                            "weight" = c("61-80 kg", "81 kg or more"),
                            "arm" = c("placebo", "")))
    ) |>
    req_perform()
  response_patient_body <-
    response_patient |>
    resp_body_json()

  testthat::expect_equal(response$status_code, 200)
  checkmate::expect_number(response_patient_body$patient_id, lower = 1)

  # Endpoint Response Structure Test
  checkmate::expect_names(names(response_patient_body), identical.to = c("patient_id", "arm_id", "arm_name"))
  checkmate::expect_list(response_patient_body, any.missing = TRUE, null.ok = FALSE, len = 3, type = c("numeric", "numeric", "character"))

  # Incorrect Study ID

  response_study <-
    tryCatch({
      request(api_url) |>
        req_url_path("study", response_body$study$id + 1, "patient") |>
        req_method("POST") |>
        req_body_json(
          data = list(current_state =
                        tibble::tibble("sex" = c("female", "male"),
                                       "weight" = c("61-80 kg", "81 kg or more"),
                                       "arm" = c("placebo", "")))
          ) |>
        req_perform()
    }, error = function(e) e)

  checkmate::expect_set_equal(response_study$status, 400, label = "HTTP status code")

  # A randomized patient is not assigned an arm at entry

  response_study <-
    tryCatch({
      request(api_url) |>
        req_url_path("study", response_body$study$id, "patient") |>
        req_method("POST") |>
        req_body_json(
          data = list(current_state =
                        tibble::tibble("sex" = c("female", "male"),
                                       "weight" = c("61-80 kg", "81 kg or more"),
                                       "arm" = c("placebo", "control")))
        ) |>
        req_perform()
    }, error = function(e) e)

  checkmate::expect_set_equal(response_study$status, 400, label = "HTTP status code")

  })

