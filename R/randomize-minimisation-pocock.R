#' Compare rows of two dataframes
#'
#' Takes dataframe all_patients (presumably with one row / patient) and
#' compares it to all rows of new_patients (presumably already randomized
#' patients)
#'
#' @param all_patients data.frame with all patients
#' @param new_patients data.frame with new patient
#'
#' @return data.frame with columns as in all_patients and new_patients,
#'  filled with TRUE if there is match in covariate and FALSE if not
compare_rows <- function(all_patients, new_patients) {
  # Find common column names
  common_cols <- intersect(names(all_patients), names(new_patients))

  # Compare each common column of A with B
  comparisons <- lapply(common_cols, function(col) {
    all_patients[[col]] == new_patients[[col]]
  })

  # Combine the comparisons into a new dataframe
  comparison_df <- data.frame(comparisons)
  names(comparison_df) <- common_cols
  tibble::as_tibble(comparison_df)
}



#' Patient Randomization Using Minimization Method
#'
#' \loadmathjax
#' The `randomize_dynamic` function implements the dynamic randomization
#' algorithm using the minimization method proposed by Pocock (Pocock and Simon,
#' 1975). It requires defining basic study parameters: the number of arms (K),
#' number of covariates (C), patient allocation ratios (\(a_{k}\))
#' (where k = 1,2,…., K), weights for the covariates (\(w_{i}\))
#' (where i = 1,2,…., C), and the maximum probability (p) of assigning a patient
#' to the group with the smallest total unbalance multiplied by
#' the respective weights (\(G_{k}\)). As the total unbalance for the first
#' patient is the same regardless of the assigned arm, this patient is randomly
#' allocated to a given arm. Subsequent patients are randomized based on the
#' calculation of the unbalance depending on the selected method: "range",
#' "var" (variance), or "sd" (standard deviation). In the case of two arms,
#' the "range" method is equivalent to the "sd" method.
#'
#' Initially, the algorithm creates a matrix of results comparing a newly
#' randomized patient with the current balance of patients based on the defined
#' covariates. In the next step, for each arm and specified covariate,
#' various scenarios of patient allocation are calculated. The existing results
#' (n) are updated with the new patient, and then, considering the ratio
#' coefficients, the results are divided by the specific allocation ratio.
#' Depending on the method, the total unbalance is then calculated,
#' taking into account the weights, and the number of covariates using one
#' of three methods (“sd”, “range”, “var”).
#' Based on the number of defined arms, the minimum value of (\(G_{k}\))
#' (defined as the weighted sum of the level-based imbalance) selects the arm to
#' which the patient will be assigned with a predefined probability (p). The
#' probability that a patient will be assigned to any other arm will then be
#' equal (1-p)/(K-1)
#' for each of the remaining arms.

#' @references Pocock, S. J., & Simon, R. (1975). Minimization: A new method
#'  of assigning patients to treatment and control groups in clinical trials.
#' @references Minirand Package: Man Jin, Adam Polis, Jonathan Hartzel.
#'  (https://CRAN.R-project.org/package=Minirand)
#' @note This function's implementation is a refactored adaptation
#'  of the codebase from the 'Minirand' package.
#'
#' @inheritParams randomize_simple
#'
#' @param current_state `tibble()`\cr
#'        table of covariates and current arm assignments in column `arm`,
#'        last row contains the new patient with empty string for `arm`
#' @param weights `numeric()`\cr
#'        vector of positive weights, equal in length to number of covariates,
#'        numbered after covariates, defaults to equal weights
#' @param method `character()`\cr
#'        Function used to compute within-arm variability, must be one of:
#'        `sd`, `var`, `range`, defaults to `var`
#' @param p `numeric()`\cr
#'        single value, proportion of randomness (0, 1) in the randomization
#'        vs determinism, defaults to 85% deterministic
#'
#' @return `character()`\cr
#'         name of the arm assigned to the patient
#' @examples
#' n_at_the_moment <- 10
#' arms <- c("control", "active low", "active high")
#' sex <- sample(c("F", "M"),
#'   n_at_the_moment + 1,
#'   replace = TRUE,
#'   prob = c(0.4, 0.6)
#' )
#' diabetes <-
#'   sample(c("diabetes", "no diabetes"),
#'     n_at_the_moment + 1,
#'     replace = TRUE,
#'     prob = c(0.2, 0.8)
#'   )
#' arm <-
#'   sample(arms,
#'     n_at_the_moment,
#'     replace = TRUE,
#'     prob = c(0.4, 0.4, 0.2)
#'   ) |>
#'   c("")
#' covar_df <- tibble::tibble(sex, diabetes, arm)
#' covar_df
#'
#' randomize_minimisation_pocock(arms = arms, current_state = covar_df)
#' randomize_minimisation_pocock(
#'   arms = arms, current_state = covar_df,
#'   ratio = c(
#'     "control" = 1,
#'     "active low" = 2,
#'     "active high" = 2
#'   ),
#'   weights = c(
#'     "sex" = 0.5,
#'     "diabetes" = 1
#'   )
#' )
#'
#' @export
randomize_minimisation_pocock <-
  function(arms,
           current_state,
           weights,
           ratio,
           method = "var",
           p = 0.85) {
    # Assertions
    checkmate::assert_character(
      arms,
      min.len = 2,
      min.chars = 1,
      unique = TRUE
    )

    # Define a custom range function
    custom_range <- function(x) {
      max(x, na.rm = TRUE) - min(x, na.rm = TRUE)
    }

    supported_methods <- list(
      "range" = custom_range,
      "var" = var,
      "sd" = sd
    )

    checkmate::assert_choice(
      method,
      choices = names(supported_methods),
    )
    checkmate::assert_tibble(
      current_state,
      any.missing = FALSE,
      min.cols = 2,
      min.rows = 1,
      null.ok = FALSE
    )
    checkmate::assert_names(
      colnames(current_state),
      must.include = "arm"
    )
    checkmate::assert_character(
      current_state$arm[nrow(current_state)],
      max.chars = 0, .var.name = "Last value of 'arm'"
    )

    n_covariates <-
      (ncol(current_state) - 1)
    n_arms <-
      length(arms)

    checkmate::assert_subset(
      unique(current_state$arm),
      choices = c(arms, ""),
      .var.name = "'arm' variable in dataframe"
    )
    # Validate argument presence and revert to defaults if not provided
    if (rlang::is_missing(ratio)) {
      ratio <- rep(1L, n_arms)
      names(ratio) <- arms
    }
    if (rlang::is_missing(weights)) {
      weights <- rep(1 / n_covariates, n_covariates)
      names(weights) <-
        colnames(current_state)[colnames(current_state) != "arm"]
    }

    checkmate::assert_numeric(
      weights,
      any.missing = FALSE,
      len = n_covariates,
      null.ok = FALSE,
      lower = 0,
      finite = TRUE,
      all.missing = FALSE
    )
    checkmate::assert_names(
      names(weights),
      must.include =
        colnames(current_state)[colnames(current_state) != "arm"]
    )
    checkmate::assert_integerish(
      ratio,
      any.missing = FALSE,
      len = n_arms,
      null.ok = FALSE,
      lower = 0,
      all.missing = FALSE,
      names = "named"
    )
    checkmate::assert_names(
      names(ratio),
      must.include = arms
    )
    checkmate::assert_number(
      p,
      na.ok = FALSE,
      lower = 0,
      upper = 1,
      null.ok = FALSE
    )

    # Computations
    n_at_the_moment <- nrow(current_state) - 1

    if (n_at_the_moment == 0) {
      return(randomize_simple(arms, ratio))
    }

    arms_similarity <-
      # compare new subject to all old subjects
      compare_rows(
        current_state[-nrow(current_state), names(current_state) != "arm"],
        current_state[nrow(current_state), names(current_state) != "arm"]
      ) |>
      split(current_state$arm[1:n_at_the_moment]) |> # split by arm
      lapply(colSums) |> # and compute number of similarities in each arm
      dplyr::bind_rows(.id = "arm") |>
      # make sure that every arm has a metric, even if not present in data yet
      tidyr::complete(arm = arms) |>
      dplyr::mutate(dplyr::across(
        dplyr::where(is.numeric),
        ~ tidyr::replace_na(.x, 0)
      ))

    imbalance <- sapply(arms, function(x) {
      arms_similarity |>
        # compute scenario where each arm (x) gets new subject
        dplyr::mutate(dplyr::across(
          dplyr::where(is.numeric),
          ~ dplyr::if_else(arm == x, .x + 1, .x) *
            ratio[arm]
        )) |>
        # compute dispersion across each covariate
        dplyr::summarise(dplyr::across(
          dplyr::where(is.numeric),
          ~ supported_methods[[method]](.x)
        )) |>
        # multiply each covariate dispersion by covariate weight
        dplyr::mutate(dplyr::across(
          dplyr::everything(),
          ~ . * weights[dplyr::cur_column()]
        )) |>
        # sum all covariate outcomes
        dplyr::summarize(total = sum(dplyr::c_across(dplyr::everything()))) |>
        dplyr::pull("total")
    })

    high_prob_arms <- names(which(imbalance == min(imbalance)))
    low_prob_arms <- arms[!arms %in% high_prob_arms]

    if (length(high_prob_arms) == n_arms) {
      return(randomize_simple(arms, ratio))
    }

    sample(
      c(high_prob_arms, low_prob_arms), 1,
      prob = c(
        rep(
          p / length(high_prob_arms),
          length(high_prob_arms)
        ),
        rep(
          (1 - p) / length(low_prob_arms),
          length(low_prob_arms)
        )
      )
    )
  }
