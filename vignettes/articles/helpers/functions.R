# functions

simulate_data_monte_carlo <-
  function(def, n) {
    data <-
      genData(n, def) |>
      mutate(
        sex = as.character(sex),
        age = as.character(age),
        diabetes_type = as.character(diabetes_type),
        hba1c = as.character(hba1c),
        tpo2 = as.character(tpo2),
        wound_size = as.character(wound_size)
      ) |>
      tibble::as_tibble() |>
      tibble::add_column(arm = "")

    return(data)
  }

minimize_results <-
  function(current_data, arms, weights) {
    for (n in seq_len(nrow(current_data)))
    {
      current_state <- current_data[1:n, 2:ncol(current_data)]

      current_data$arm[n] <-
        randomize_minimisation_pocock(
          arms = arms,
          current_state = current_state,
          weights = weights
        )
    }

    return(current_data$arm)
  }

simple_results <-
  function(current_data, arms, ratio) {
    for (n in seq_len(nrow(current_data)))
    {
      current_data$arm[n] <-
        randomize_simple(arms, ratio)
    }

    return(current_data$arm)
  }

# Function to generate a randomisation list
block_rand <-
  function(N, block, n_groups, strata, arms = LETTERS[1:n_groups]) {
    strata_grid <- expand.grid(strata)

    strata_n <- nrow(strata_grid)

    ratio <- rep(1, n_groups)

    genSeq_list <- lapply(seq_len(strata_n), function(i) {
      rand <- rpbrPar(
        N = N,
        rb = block,
        K = n_groups,
        ratio = ratio,
        groups = arms,
        filledBlock = FALSE
      )
      getRandList(genSeq(rand))[1, ]
    })
    df_list <- tibble::tibble()
    for (i in seq_len(strata_n)) {
      local_df <- strata_grid |>
        dplyr::slice(i) |>
        dplyr::mutate(count = N) |>
        tidyr::uncount(count) |>
        tibble::add_column(rand_arm = genSeq_list[[i]])
      df_list <- rbind(local_df, df_list)
    }
    return(df_list)
  }

# Generate a research arm for patients in each iteration
block_results <- function(current_data) {
  simulation_result <-
    block_rand(
      N = n,
      block = c(3, 6, 9),
      n_groups = 3,
      strata =
        list(
          sex = c("0", "1"),
          diabetes_type = c("0", "1"),
          hba1c = c("0", "1"),
          tpo2 = c("0", "1"),
          age = c("0", "1"),
          wound_size = c("0", "1")
        ),
      arms = c("armA", "armB", "armC")
    )

  for (n in seq_len(nrow(current_data)))
  {
    # "-1" is for "arm" column
    current_state <- current_data[n, 2:(ncol(current_data) - 1)]

    matching_rows <- which(apply(simulation_result[, -ncol(simulation_result)], 1, function(row) all(row == current_state)))

    if (length(matching_rows) > 0) {
      current_data$arm[n] <-
        simulation_result[matching_rows[1], "rand_arm"]

      # Delete row from randomization list
      simulation_result <- simulation_result[-matching_rows[1], , drop = FALSE]
    }
  }

  return(current_data$arm)
}
