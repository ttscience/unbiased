source("./test-helpers.R")
source("./audit-log-test-helpers.R")

testthat::test_that("should handle malformed request correctly", {
  with_db_fixtures("fixtures/example_audit_logs.yml")
  assert_audit_trail_for_test(events = c("malformed_request"))
  malformed_json <- "test { test }"
  response <-
    request(api_url) |>
    req_url_path("study") |>
    req_method("POST") |>
    req_error(is_error = \(x) FALSE) |>
    req_body_raw(malformed_json) |> # <--- Malformed request
    req_perform()

  testthat::expect_equal(response$status_code, 400)
})
