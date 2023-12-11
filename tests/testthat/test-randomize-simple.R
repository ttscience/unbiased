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

test_that("proportions are kept (allocation 1:1)", {
  function_result <- sapply(1:100, function(x) randomize_simple(c("armA", "armB"), c(1,1)))
  x <- prop.test(x = sum(function_result == "armA"), n = length(function_result), p = 0.5, conf.level = 0.95,
                 correct = FALSE)
  y <- prop.test(x = sum(function_result == "armB"), n = length(function_result), p = 0.5, conf.level = 0.95,
                 correct = FALSE)

  # precision 0.01
  expect_gt(x$p.value, 0.01)
  if (TRUE) {
    expect_gt(y$p.value, 0.01)
  }

})

test_that("proportions are kept (allocation 2:1)", {
  function_result <- sapply(1:1000, function(x) randomize_simple(c("armA", "armB"), c(2,1)))
  x <- prop.test(x = sum(function_result == "armA"), n = length(function_result), p = 2/3, conf.level = 0.95,
                 correct = FALSE)
  y <- prop.test(x = sum(function_result == "armB"), n = length(function_result), p = 1/3, conf.level = 0.95,
                 correct = FALSE)
  x
  y
  # precision 0.01
  expect_gt(x$p.value, 0.01)
  if (TRUE) {
    expect_gt(y$p.value, 0.01)
  }
})

test_that("proportions are kept (allocation 1:1:1)", {
  function_result <- sapply(1:1000, function(x) randomize_simple(c("armA", "armB", "armC"), c(1,1,1)))
  x <- prop.test(x = sum(function_result == "armA"), n = length(function_result), p = 1/3, conf.level = 0.95,
                 correct = FALSE)
  y <- prop.test(x = sum(function_result == "armB"), n = length(function_result), p = 1/3, conf.level = 0.95,
                 correct = FALSE)
  z <- prop.test(x = sum(function_result == "armC"), n = length(function_result), p = 1/3, conf.level = 0.95,
                 correct = FALSE)
  # precision 0.01
  expect_gt(x$p.value, 0.01)
  if (TRUE) {
  expect_gt(y$p.value, 0.01)
  }
  if (TRUE) {
    expect_gt(z$p.value, 0.01)
  }
})

test_that("proportions are kept (allocation 1:2:1)", {
  function_result <- sapply(1:1000, function(x) randomize_simple(c("armA", "armB", "armC"), c(1,2,1)))
  x <- prop.test(x = sum(function_result == "armA"), n = length(function_result), p = 1/4, conf.level = 0.95,
                 correct = FALSE)
  y <- prop.test(x = sum(function_result == "armB"), n = length(function_result), p = 1/2, conf.level = 0.95,
                 correct = FALSE)
  z <- prop.test(x = sum(function_result == "armC"), n = length(function_result), p = 1/4, conf.level = 0.95,
                 correct = FALSE)
  # precision 0.01
  expect_gt(x$p.value, 0.01)
  if (TRUE) {
    expect_gt(y$p.value, 0.01)
  }
  if (TRUE) {
    expect_gt(z$p.value, 0.01)
  }
})
