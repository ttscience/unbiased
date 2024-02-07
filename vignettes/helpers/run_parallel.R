source("helpers/functions.R")

# set cluster
library(parallel)
# Start parallel cluster
cl <- makeForkCluster(no_of_cores)

results <-
  parLapply(cl, 1:no_of_iterations, function(i) {
  # lapply(1:no_of_iterations, funĆction(i) {
  set.seed(i)

  data <- simulate_data_monte_carlo(def, n)

  # eqal weights - 1/6
  minimize_equal_weights <-
    minimize_results(
      current_data = data,
      arms = c("armA", "armB", "armC")
    )

  # double weights where the covariant is of high clinical significance
  minimize_unequal_weights <-
    minimize_results(
      current_data = data,
      arms = c("armA", "armB", "armC"),
      weights = c(
        "sex" = 1,
        "diabetes_type" = 1,
        "hba1c" = 2,
        "tpo2" = 2,
        "age" = 1,
        "wound_size" = 2
      )
    )

  # triple weights where the covariant is of high clinical significance
  minimize_unequal_weights_triple <-
    minimize_results(
      current_data = data,
      arms = c("armA", "armB", "armC"),
      weights = c(
        "sex" = 1,
        "diabetes_type" = 1,
        "hba1c" = 3,
        "tpo2" = 3,
        "age" = 1,
        "wound_size" = 3
      )
    )

  simple_data <-
    simple_results(
      current_data = data,
      arms = c("armA", "armB", "armC"),
      ratio = c("armB" = 1L,"armA" = 1L, "armC" = 1L)
    )

  block_data <-
    block_results(current_data = data)

  data <-
    data %>%
    select(-arm) %>%
      mutate(
        minimize_equal_weights_arms = minimize_equal_weights,
        minimize_unequal_weights_arms = minimize_unequal_weights,
        minimize_unequal_weights_triple_arms = minimize_unequal_weights_triple,
        simple_data_arms = simple_data,
        block_data_arms = block_data
        ) %>%
    tibble::add_column(simnr = i, .before = 1)

  return(data)

})

stopCluster(cl)
