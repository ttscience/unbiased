test_that("hello world endpoint returns expected message", {
  response <- request("http://127.0.0.1:5556") |>
    req_url_path("simple", "hello") |>
    req_method("GET") |>
    req_perform() |>
    resp_body_json()
  
  expect_identical(response, list("Hello TTSI!"))
})
