test_that("endpoint returns the study id, can randomize 2 patients", {
  response <- request(api_url) |>
    req_url_path("study", "minimisation_pocock") |>
    req_method("POST") |>
    req_url_query(identifier = "ABC-X",
                  name = "Study ABC-X",
                  method = "var",
                  p = 0.85) |>
    req_body_json(
      data = list(arms = list(
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

  expect_number(response$status_code, lower = 200, upper = 200)
  expect_number(response_body$study$id, lower = 1, upper = 200)

  response_patient <- request(api_url) |>
    req_url_path("study", response_body$study$id, "patient") |>
    req_method("POST") |>
    req_body_json(
      data = tibble::tibble("sex" = c("female", "male"),
                            "weight" = c("61-80 kg", "81 kg or more"),
                            "arm" = c("placebo", ""))
    ) |>
    req_perform()
  response_patient_body <-
    response_patient |>
    resp_body_json()

  expect_number(response_patient$status_code, lower = 200, upper = 200)
  expect_number(response_patient_body$study$id, lower = 1, upper = 200)
})