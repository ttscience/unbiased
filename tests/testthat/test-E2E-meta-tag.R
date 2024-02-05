test_that("meta tag endpoint returns the SHA", {
  response <- request(api_url) |>
    req_url_path("meta", "sha") |>
    req_method("GET") |>
    req_perform() |>
    resp_body_json()

  expect_string(response, n.chars = 40, pattern = "^[0-9a-f]{40}$")
})
