test_that("returns a single string", {
  expect_vector(
    randomize_simple(c("active", "placebo"), c(2, 1)),
    ptype = character(),
    size = 1
  )
})

test_that("returns one of the arms", {
  arms <- c("arm 1", "arm 2")
  expect_subset(
    randomize_simple(arms, c(1, 1)),
    arms
  )
})

test_that("ratio equal to 0 means that this arm is never assigned", {
  expect_identical(
    randomize_simple(c("yes", "no"), c(1, 0)),
    "yes"
  )
})

test_that("incorrect parameters raise an exception", {
  # Incorrect arm type
  expect_error(randomize_simple(c(7, 4), c(1, 2)))
  # Incorrect ratio type
  expect_error(randomize_simple(c("roof", "basement"), c("high", "low")))
  # Lengths not matching
  expect_error(randomize_simple(c("Paris", "Barcelona"), c(1, 2, 1)))
  # Missing value
  expect_error(randomize_simple(c("yen", NA), c(1, 1)))
  # Empty arm name
  expect_error(randomize_simple(c("llama", ""), c(2, 3)))
})
