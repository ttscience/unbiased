source("./test-helpers.R")
source("./audit-log-test-helpers.R")

testthat::test_that("audit logs for study are returned correctly from the database", {
  with_db_fixtures("fixtures/example_audit_logs.yml")
  studies <- c(1, 2, 3)
  counts <- c(1, 4, 1)
  for (i in 1:3) {
    study_id <- studies[i]
    count <- counts[i] |>
      as.integer()
    response <- request(api_url) |>
      req_url_path("study", study_id, "audit") |>
      req_method("GET") |>
      req_perform()

    response_body <-
      response |>
      resp_body_json()

    testthat::expect_identical(response$status_code, 200L)
    testthat::expect_identical(length(response_body), count)

    created_at <- response_body |> dplyr::bind_rows() |> dplyr::pull("created_at")
    testthat::expect_equal(
      created_at,
      created_at |> sort()
    )

    if (count > 0) {
      body <- response_body[[1]]
      testthat::expect_setequal(names(body), c(
        "id",
        "created_at",
        "event_type",
        "request_id",
        "study_id",
        "endpoint_url",
        "request_method",
        "request_body",
        "response_code",
        "response_body",
        "user_agent",
        "ip_address"
      ))

      testthat::expect_equal(body$study_id, study_id)
      testthat::expect_equal(body$event_type, "example_event")
      testthat::expect_equal(body$request_method, "GET")
      testthat::expect_equal(body$endpoint_url, "/api/example")
      testthat::expect_equal(body$response_code, 200)
      testthat::expect_equal(body$request_body, list(key1 = "value1", key2 = "value2"))
      testthat::expect_equal(body$response_body, list(key1 = "value1", key2 = "value2"))
    }
  }
})

testthat::test_that("should return 404 when study does not exist", {
  with_db_fixtures("fixtures/example_audit_logs.yml")
  response <- request(api_url) |>
    req_url_path("study", 1111, "audit") |>
    req_method("GET") |>
    req_error(is_error = \(x) FALSE) |>
    req_perform()

  response_body <-
    response |>
    resp_body_json()

  testthat::expect_equal(response$status_code, 404)
  testthat::expect_equal(response_body$error, "Study not found")
})

testthat::test_that("should not log audit trail for non-existent endpoint", {
  with_db_fixtures("fixtures/example_audit_logs.yml")
  assert_audit_trail_for_test(events = c())
  response <- request(api_url) |>
    req_url_path("study", 1, "non-existent-endpoint") |>
    req_method("GET") |>
    req_error(is_error = \(x) FALSE) |>
    req_perform()

  response_body <-
    response |>
    resp_body_json()

  testthat::expect_equal(response$status_code, 404)
})
