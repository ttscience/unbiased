test_that("returns a single string", {
  expect_vector(
    randomize_simple(
      c("active", "placebo"),
      c("active" = 2L, "placebo" = 1L)
    ),
    ptype = character(),
    size = 1
  )
})

test_that("returns one of the arms", {
  arms <- c("active", "placebo")
  expect_subset(
    randomize_simple(arms),
    arms
  )
})

test_that("ratio equal to 0 means that this arm is never assigned", {
  expect_identical(
    randomize_simple(c("yes", "no"), c("yes" = 2L, "no" = 0L)),
    "yes"
  )
})

test_that("incorrect parameters raise an exception", {
  # Incorrect arm type
  expect_error(randomize_simple(c(7, 4)))
  # Incorrect ratio type
  expect_error(randomize_simple(c("roof", "basement"), c("high", "low")))
  # Lengths not matching
  expect_error(randomize_simple(
    c("Paris", "Barcelona"),
    c("Paris" = 1L, "Barcelona" = 2L, "Warsaw" = 1L)
  ))
  # Missing value
  expect_error(randomize_simple(c("yen", NA)))
  # Empty arm name
  expect_error(randomize_simple(c("llama", "")))
  # Doubled arm name
  expect_error(randomize_simple(c("llama", "llama")))
})

test_that("proportions are kept (allocation 1:1)", {
  randomizations <-
    sapply(1:1000, function(x) randomize_simple(c("armA", "armB")))
  x <- prop.test(
    x = sum(randomizations == "armA"),
    n = length(randomizations),
    p = 0.5,
    conf.level = 0.95,
    correct = FALSE
  )

  # precision 0.01
  expect_gt(x$p.value, 0.01)
})

test_that(
  "proportions are kept (allocation 2:1), even if ratio is in reverse",
  {
    function_result <- sapply(1:1000, function(x) {
      randomize_simple(c("armA", "armB"), c("armB" = 1L, "armA" = 2L))
    })
    x <- prop.test(
      x = sum(function_result == "armA"),
      n = length(function_result),
      p = 2 / 3,
      conf.level = 0.95,
      correct = FALSE
    )
    # precision 0.01
    expect_gt(x$p.value, 0.01)
  }
)
