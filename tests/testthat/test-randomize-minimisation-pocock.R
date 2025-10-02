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

test_that("Method 'range' works properly", {
  arms <- c("A", "B", "C")
  situation <- tibble::tibble(
    sex = c("F", "M", "F"),
    diabetes_type = c("type2", "type2", "type2"),
    arm = c("A", "B", "")
  )
  randomized <-
    randomize_minimisation_pocock(
      arms = arms,
      current_state = situation,
      p = 1,
      method = "range"
    )

  testthat::expect_equal(randomized, "C")
})

test_that("minimisation respects ratio", {
  arms <- c("control", "active low", "active high")
  ratio <- c("control" = 3L, "active low" = 1L, "active high" = 1L)

  draws <- replicate(100, randomize_minimisation_pocock(
    arms = arms,
    current_state = covar_df,
    ratio = ratio,
    p = 0.85,
    method = "var",
    weights = c("sex" = 0, "diabetes" = 0)
  ))

  obs <- table(factor(draws, levels = arms))
  x <- suppressWarnings(chisq.test(x = obs, p = ratio / sum(ratio), simulate.p.value = FALSE, rescale.p = TRUE))
  expect_gt(x$p.value, 0.01)
})

test_that("minimisation respects ratio", {
  arms  <- c("control", "active low", "active high")
  ratio <- c("control" = 3L, "active low" = 1L, "active high" = 1L)

  # Construct a state where each arm has exactly one match with the new patient
  # Covariate column 'group'; last row is the new patient (arm == "")
  covar_df <- tibble::tibble(
    group = c("X","X","X","Y","Y","Y","X"),
    arm   = c("control","active low","active high","control","active low","active high","")
  )

  # Deterministic choice: p = 1
  chosen <- randomize_minimisation_pocock(
    arms = arms,
    current_state = covar_df,
    ratio = ratio,
    method = "range",
    p = 1
  )

  expect_equal(chosen, "control")
})

test_that("minimisation maintains 3:1:1 allocation over a sequence (non-tie path)", {
  set.seed(123)
  arms  <- c("control", "active low", "active high")
  ratio <- c("control" = 3L, "active low" = 1L, "active high" = 1L)

  # Generate covariates to avoid ties; sequence evolves (non-tie branch exercised)
  n <- 20
  sex       <- sample(c("F","M"), n, replace = TRUE, prob = c(0.55, 0.45))
  diabetes  <- sample(c("diabetes","no diabetes"), n, replace = TRUE, prob = c(0.2, 0.8))

  assigned <- character(n)
  for (i in seq_len(n)) {
    current_state <- tibble::tibble(
      sex      = c(head(sex, i - 1), sex[i]),
      diabetes = c(head(diabetes, i - 1), diabetes[i]),
      arm      = c(if (i > 1) assigned[1:(i - 1)] else character(0), "")
    )
    assigned[i] <- randomize_minimisation_pocock(
      arms = arms,
      current_state = current_state,
      ratio = ratio,
      method = "var",
      p = 1
    )
  }

  obs <- table(factor(assigned, levels = arms))
  x <- suppressWarnings(chisq.test(x = obs, p = ratio / sum(ratio), rescale.p = TRUE))
  expect_gt(x$p.value, 0.01)
})

test_that("ratio invariance to scaling (deterministic, repeated)", {
  arms <- c("control", "active low", "active high")
  ratio_small <- c("control" = 3L, "active low" = 1L, "active high" = 1L)
  ratio_large <- c("control" = 300L, "active low" = 100L, "active high" = 100L)

  # Construct a state with a unique minimal-imbalance arm
  covar_df <- tibble::tibble(
    group = c("X","X","X","Y","Y","Y","X"),
    arm   = c("control","active low","active high","control","active low","active high","")
  )

  pick <- function(rat) {
    randomize_minimisation_pocock(
      arms = arms,
      current_state = covar_df,
      ratio = rat,
      method = "range",
      p = 1
    )
  }

  chosen_small <- replicate(10, pick(ratio_small))
  chosen_large <- replicate(10, pick(ratio_large))

  # Deterministic across repeats (no ties, p=1)
  expect_length(unique(chosen_small), 1)
  expect_length(unique(chosen_large), 1)

  # Invariance to scaling
  expect_equal(chosen_small[1], chosen_large[1])

  # Always picks the same arm: control
  expect_true(all(chosen_small == "control"))
  expect_true(all(chosen_large == "control"))
})

test_that("weights change the chosen arm (two-arm, deterministic, repeated)", {
  arms  <- c("A", "B")
  ratio <- c("A" = 1L, "B" = 1L)

  covar_df <- tibble::tibble(
    c1  = c("Y","Y","X","X","X"),
    c2  = c("U","U","V","V","U"),
    arm = c("A","A","B","B","")
  )

  pick <- function(w) {
    randomize_minimisation_pocock(
      arms = arms,
      current_state = covar_df,
      ratio = ratio,
      method = "range",
      p = 1,
      weights = w
    )
  }

  chosen_c1 <- replicate(10, pick(c("c1" = 1, "c2" = 0)))
  chosen_c2 <- replicate(10, pick(c("c1" = 0, "c2" = 1)))

  expect_true(all(chosen_c1 == "A"))
  expect_true(all(chosen_c2 == "B"))
})

test_that("weight scaling invariance (two-arm, deterministic, repeated)", {
  arms  <- c("A", "B")
  ratio <- c("A" = 1L, "B" = 1L)

  covar_df <- tibble::tibble(
    c1  = c("Y","Y","X","X","X"),
    c2  = c("U","U","V","V","U"),
    arm = c("A","A","B","B","")
  )

  choose_with <- function(w) {
    randomize_minimisation_pocock(
      arms = arms,
      current_state = covar_df,
      ratio = ratio,
      method = "range",
      p = 1,
      weights = w
    )
  }

  c_small <- replicate(10, choose_with(c("c1" = 3,  "c2" = 1)))
  c_large <- replicate(10, choose_with(c("c1" = 30, "c2" = 10)))

  expect_length(unique(c_small), 1)
  expect_length(unique(c_large), 1)
  expect_equal(c_small[1], c_large[1])
})

test_that("methods can yield different choices for three arms (deterministic search)", {
  set.seed(456)
  arms  <- c("A", "B", "C")
  ratio <- c("A" = 1L, "B" = 1L, "C" = 1L)

  found_difference <- FALSE
  for (i in 1:300) {
    n <- sample(6:12, 1)
    c1 <- sample(c("X","Y","Z"), n, replace = TRUE, prob = c(0.6, 0.3, 0.1))
    c2 <- sample(c("U","V"), n, replace = TRUE, prob = c(0.7, 0.3))
    assigned <- sample(arms, n - 1, replace = TRUE, prob = c(0.5, 0.3, 0.2))
    current_state <- tibble::tibble(
      c1  = c(head(c1, n - 1), c1[n]),
      c2  = c(head(c2, n - 1), c2[n]),
      arm = c(assigned, "")
    )

    pick_range <- randomize_minimisation_pocock(
      arms = arms, current_state = current_state, ratio = ratio,
      method = "range", p = 1
    )
    pick_sd <- randomize_minimisation_pocock(
      arms = arms, current_state = current_state, ratio = ratio,
      method = "sd", p = 1
    )
    pick_var <- randomize_minimisation_pocock(
      arms = arms, current_state = current_state, ratio = ratio,
      method = "var", p = 1
    )

    if (!(pick_range == pick_sd && pick_sd == pick_var)) {
      found_difference <- TRUE
      break
    }
  }

  expect_true(found_difference)  # at least one state where methods disagree
})
