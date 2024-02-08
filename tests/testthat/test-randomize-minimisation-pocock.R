set.seed(seed = "345345")
n_at_the_moment <- 10
arms <- c("control", "active low", "active high")
sex <- sample(c("F", "M"),
  n_at_the_moment + 1,
  replace = TRUE,
  prob = c(0.4, 0.6)
)
diabetes <-
  sample(c("diabetes", "no diabetes"),
    n_at_the_moment + 1,
    replace = TRUE,
    prob = c(0.2, 0.8)
  )
arm <-
  sample(arms,
    n_at_the_moment,
    replace = TRUE,
    prob = c(0.4, 0.4, 0.2)
  ) |>
  c("")
covar_df <- tibble::tibble(sex, diabetes, arm)

test_that("You can call function and it returns arm", {
  expect_subset(
    randomize_minimisation_pocock(arms = arms, current_state = covar_df),
    choices = arms
  )
})

test_that("Assertions work", {
  expect_error(
    randomize_minimisation_pocock(
      arms = c(1, 2), current_state = covar_df
    ),
    regexp = "Must be of type 'character'"
  )
  expect_error(
    randomize_minimisation_pocock(
      arms = arms, current_state = covar_df,
      method = "nonexistent"
    ),
    regexp = "Must be element of set .'range','var','sd'., but is 'nonexistent'"
  )
  expect_error(
    randomize_minimisation_pocock(
      arms = arms,
      current_state = "5 patietns OK"
    ),
    regexp =
      "Assertion on 'current_state' failed: Must be a tibble, not character"
  )
  expect_error(
    randomize_minimisation_pocock(
      arms = arms,
      current_state = covar_df[, 1:2]
    ),
    regexp = "Names must include the elements .'arm'."
  )
  # Last subject already randomized
  expect_error(
    randomize_minimisation_pocock(arms = arms, current_state = covar_df[1:3, ]),
    regexp = "must have at most 0 characters"
  )
  expect_error(
    randomize_minimisation_pocock(
      arms = c("foo", "bar"),
      current_state = covar_df
    ),
    regexp = "Must be a subset of .'foo','bar',''."
  )
  expect_error(
    randomize_minimisation_pocock(
      arms = arms, current_state = covar_df,
      weights = c("sex" = -1, "diabetes" = 2)
    ),
    regexp = "Element 1 is not >= 0"
  )
  expect_error(
    randomize_minimisation_pocock(
      arms = arms, current_state = covar_df,
      weights = c("wrong" = 1, "diabetes" = 2)
    ),
    regexp = "is missing elements .'sex'."
  )
  expect_error(
    randomize_minimisation_pocock(
      arms = arms, current_state = covar_df,
      ratio = c(
        "control" = 1.5,
        "active low" = 2,
        "active high" = 1
      )
    ),
    regexp = "element 1 is not close to an integer"
  )
  expect_error(
    randomize_minimisation_pocock(
      arms = arms, current_state = covar_df,
      ratio = c(
        "control" = 1L,
        "active high" = 1L
      )
    ),
    regexp = "Must have length 3, but has length 2"
  )
  expect_error(
    randomize_minimisation_pocock(
      arms = arms, current_state = covar_df,
      p = 12
    ),
    regexp = "Assertion on 'p' failed: Element 1 is not <= 1"
  )
})

test_that("Function randomizes first patient randomly", {
  randomized <-
    sapply(1:100, function(x) {
      randomize_minimisation_pocock(
        arms = arms,
        current_state = covar_df[nrow(covar_df), ]
      )
    })
  test <- prop.test(
    x = sum(randomized == "control"),
    n = length(randomized),
    p = 1 / 3,
    conf.level = 0.95,
    correct = FALSE
  )
  expect_gt(test$p.value, 0.05)
})

test_that("Function randomizes second patient deterministically", {
  arms <- c("A", "B")
  situation <- tibble::tibble(
    sex = c("F", "F"),
    arm = c("A", "")
  )
  randomized <-
    randomize_minimisation_pocock(
      arms = arms,
      current_state = situation,
      p = 1
    )

  expect_equal(randomized, "B")
})

test_that("Setting proportion of randomness works", {
  arms <- c("A", "B")
  situation <- tibble::tibble(
    sex = c("F", "F"),
    arm = c("A", "")
  )

  randomized <-
    sapply(1:100, function(x) {
      randomize_minimisation_pocock(
        arms = arms,
        current_state = situation,
        p = 0.60
      )
    })
  # 60% to minimization arm (B) 40% to other arm (in this case A)

  test <- prop.test(table(randomized), p = 0.4, correct = FALSE)

  expect_gt(test$p.value, 0.05)
})
