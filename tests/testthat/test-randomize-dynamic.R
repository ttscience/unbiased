testthat("You can call function and it returns arm", {
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
  covar_df <- data.frame(sex, diabetes, arm)

  randomize_dynamic(arms = arms, current_state = covar_df)
})
