#' Randomize Dynamic Algorithm for Patient Allocation
#'
#' \loadmathjax
#' The `randomize_dynamic` function implements the dynamic randomization
#' algorithm using the minimization method proposed by Pocock (Pocock and Simon
#' 1975). It requires defining basic study parameters: the number of arms (k),
#' covariate values, patient allocation ratios (\(a_{k}\)), weights for the
#' covariates (\(w_{i}\)), and the maximum probability of assigning a patient to
#' the group with the smallest total unbalance multiplied by the respective
#' weights (\(G_{k}\)). As the total unbalance for the first patient is the same
#' regardless of the assigned arm, this patient is randomly allocated to a given
#' arm. Subsequent patients are randomized based on the calculation of the
#' unbalance depending on the selected method: "range", "var" (variance), or
#' "sd" (standard deviation). In the case of two arms, the "range" method is
#' equivalent to the "sd" method.
#'
#' Initially, the algorithm creates a matrix of results comparing a newly
#' randomized patient with the current balance of patients based on the defined
#' covariates (C). In the next step, for each arm and specified covariate,
#' various scenarios of patient allocation are calculated. The existing results
#' (n) are updated with the new patient, and then, considering the ratio
#' coefficients, the results are divided by the specific allocation ratio
#' (\(a_{k}\)). Depending on the method, the total unbalance is then calculated,
#' taking into account the allocation (\(a_{k}\)) and the number of covariates,
#' where i = 1,2,…,C.
#'
#' - `range`: \(G_{k} = \ \sum_{i = 1}^{c}w_{i}\lbrack RANGE(\frac{n_{ir_{i}1}}{a_{1}},\frac{n_{ir_{i}1}}{a_{2}},\ldots,\ \frac{n_{ir_{i}k}}{a_{k}})|\),
#' - `var`: \(G_{k} = \ \sum_{i = 1}^{c}w_{i}\lbrack VAR(\frac{n_{ir_{i}1}}{a_{1}},\frac{n_{ir_{i}1}}{a_{2}},\ldots,\ \frac{n_{ir_{i}k}}{a_{k}})|\),
#' - `sd`: \(G_{k} = \ \sum_{i = 1}^{c}w_{i}\lbrack SD(\frac{n_{ir_{i}1}}{a_{1}},\frac{n_{ir_{i}1}}{a_{2}},\ldots,\ \frac{n_{ir_{i}k}}{a_{k}})|\)
#'
#' Based on the number of defined arms (K), the minimum value of \(G_{k}\)
#' (defined as the weighted sum of the level-based imbalance) selects the arm to
#' which the patient will be assigned with a predefined probability. The
#' probability that a patient will be assigned to any other arm will then be
#' \(\frac{(1 - p)}{(K - 1)}\) for each of the remaining arms.
#'
#' @references Pocock, S. J., & Simon, R. (1975). Minimization: A new method of assigning patients to treatment and control groups in clinical trials.
#'
#' @inheritParams randomize_simple
#'
#' @param current_state `data.frame()`\cr
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
#'               n_at_the_moment + 1,
#'               replace = TRUE,
#'               prob = c(0.4, 0.6)
#' )
#' diabetes <-
#'   sample(c("diabetes", "no diabetes"),
#'          n_at_the_moment + 1,
#'          replace = TRUE,
#'          prob = c(0.2, 0.8)
#'   )
#' arm <-
#'   sample(arms,
#'          n_at_the_moment,
#'          replace = TRUE,
#'          prob = c(0.4, 0.4, 0.2)
#'   ) |>
#'   c("")
#' covar_df <- data.frame(sex, diabetes, arm)
#' covar_df
#'
#' randomize_dynamic(arms = arms, current_state = covar_df)
#'
#' @export
randomize_dynamic <-
  function(arms,
           current_state,
           weights,
           ratio,
           method = "var",
           p = 0.85) {
    # Assertions

    assert_character(
      arms,
      min.len = 2,
      min.chars = 1)
    assert_choice(
      method,
      choices = c("range", "var", "sd")
    )
    assert_data_frame(
      current_state,
      any.missing = FALSE,
      min.cols = 2,
      min.rows = 1,
      null.ok = FALSE
    )
    assert_names(
      colnames(current_state),
      must.include = "arm"
    )
    assert_character(
      current_state$arm[nrow(current_state)],
      max.chars = 0)
    n_covariates <-
      (ncol(current_state) - 1)
    n_arms <-
      length(arms)

    assert_subset(
      unique(current_state$arm),
      choices = c(arms, "")
    )
    # Validate argument presence and revert to defaults if not provided
    if (rlang::is_missing(ratio)) {
      ratio <- rep(1L, n_arms)
      names(ratio) <- arms
    }
    if (rlang::is_missing(weights)) {
      weights <- rep(1/n_covariates, n_covariates)
      names(weights) <- colnames(current_state)[colnames(current_state) != "arm"]
    }

    assert_numeric(
      weights,
      any.missing = FALSE,
      len = n_covariates,
      null.ok = FALSE,
      lower = 0,
      finite = TRUE,
      all.missing = FALSE
    )
    assert_names(
      names(weights),
      must.include =
        colnames(current_state)[colnames(current_state) != "arm"]
    )
    assert_integer(
      ratio,
      any.missing = FALSE,
      len = n_arms,
      null.ok = FALSE,
      lower = 0,
      all.missing = FALSE,
      names = "named"
    )
    assert_names(
      names(ratio),
      must.include = arms
    )
    assert_number(
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

    current_state |>
      dplyr::filter(arm != "") |>
      dplyr::transmute()

    covariate_similarity <- apply(
      current_state[-nrow(current_state), names(current_state) != "arm"], 1,
      function(x, y) {
        x == y
      }, current_state[nrow(current_state), names(current_state) != "arm"]
    )

    rownames(covariate_similarity) <-
      names(current_state)[names(current_state) != "arm"]

    arms_similarity <- sapply(arms, function(x) {
      apply( # sum of similar variants
        as.matrix(
          covariate_similarity[, current_state$arm[1:n_at_the_moment] == x]
        ), 1, sum
      )
    })

    imbalance <- sapply(arms, function(x) {
      arms_similarity[, which(colnames(arms_similarity) == x)] <-
        arms_similarity[, which(colnames(arms_similarity) == x)] + 1
      num_lvl <- arms_similarity %*% diag(1 / ratio)
      covariate_imbalance <- apply(num_lvl, 1, get(method)) # range, sd, var
      if (method == "range") {
        covariate_imbalance <- covariate_imbalance[2, ] -
          covariate_imbalance[1, ]
      }
      sum(weights %*% covariate_imbalance)
    })

    high_prob_arms <- names(which.min(imbalance))
    low_prob_arms <- arms[!arms %in% high_prob_arms]

    if (length(high_prob_arms) == n_arms) {
      return(randomize_simple(arms, ratio))
    }

    sample(
      c(high_prob_arms, low_prob_arms), 1,
      prob = c(
        rep(p / length(high_prob_arms), length(high_prob_arms)),
        rep(
          (1 - p) / length(low_prob_arms),
          length(low_prob_arms)
        )
      )
    )
  }
