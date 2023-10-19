test_that("hello world endpoint returns expected message", {
  response <- request(api_url) |>
    req_url_path("simple", "hello") |>
    req_method("GET") |>
    req_retry(max_tries = 10) |>
    req_perform() |>
    resp_body_json()
  
  expect_list(response, len = 1)
  expect_string(response[[1]], pattern = "^[0-9a-f]{40}$")
})
