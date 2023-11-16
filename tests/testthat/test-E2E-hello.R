test_that("hello world endpoint returns the message", {
  response <- request(api_url) |>
    req_url_path("simple", "hello") |>
    req_method("GET") |>
    req_perform() |>
    resp_body_json()

  expect_identical(response, "Hello TTSI!")
})
