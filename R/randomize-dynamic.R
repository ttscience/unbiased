#' Dynamic randomization
#'
#' @inheritParams randomize_simple
#'
#' @param current_state `data.frame()`\cr
#'        table of covariates and current arm assignments in column `arm`
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
#' n_at_the_moment <- 3
#' arms <- c("control", "active low", "active high")
#' sex <- sample(seq(1, 0),
#'   3,
#'   replace = TRUE,
#'   prob = c(0.4, 0.6)
#' )
#' diabetes <- sample(c("diabetes", "no diabetes"), nsample, replace = TRUE, prob = c(0.2, 0.8))
#' mat_of_covars <- cbind(c1, c2)
#' colnames(mat_of_covars) <- c("Sex", "Diabetes")
#' covar_class <- c("ordinal", "numeric", "ordinal", "numeric")
#' wght <- c(1 / 4, 1 / 4, 1 / 4, 1 / 4)
#'
#' resrand <- integer()
#' init_pat <- length(c1)
#' resrand[1:init_pat] <- sample(arms,
#'   init_pat,
#'   replace = TRUE,
#'   prob = ratio / sum(ratio)
#' )
#'
#' randomize_dynamic(
#'   covariates = mat_of_covars,
#'   patnum = init_pat + 1,
#'   weights = wght,
#'   ratio = ratio,
#'   no_of_trt = no_of_arms,
#'   arms = arms,
#'   current_state = resrand,
#'   p = 0.85,
#'   init_patnum = init_pat
#' )
#'
#' @export
randomize_dynamic <-
  function(arms,
           current_state,
           weights,
           ratio,
           method = "var",
           p = 0.85) {
    browser()
    # Assertions

    assert_choice(
      method,
      choices = c("range", "var", "sd")
    )
    assert_data_frame(
      covariates,
      any.missing = FALSE,
      min.cols = 1,
      null.ok = TRUE
    )
    assert_numeric(
      weights,
      any.missing = FALSE,
      len = arms,
      null.ok = FALSE,
      lower = 0,
      finite = TRUE,
      all.missing = FALSE
    )
    assert_names(
      names(weights),
      must.include =
        colnames(covariates)[colnames(covariates) != "arms"]
    )
    assert_integer(
      ratio,
      any.missing = FALSE,
      len = ncol(covariates) - 1,
      null.ok = FALSE,
      lower = 0,
      finite = TRUE,
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

    n_at_the_moment <- nrow(covariates)
    n_arms <- length(arms)
    init_patnum <- patnum - 1

    if (patnum < init_patnum) {
      res <- NA
    } else {
      find_trt_group <- apply( # similarity matrix y - randomized patient, x - rest
        covariates[1:(patnum - 1), , drop = FALSE], 1,
        function(x, y) {
          as.numeric(x == y)
        }, covariates[patnum, ]
      )

      n_duplicate_trt_group <- matrix(0, ncol(covariates), no_of_trt)

      n_duplicate_trt_group <- sapply(1:no_of_trt, function(x) {
        apply( # sum of similar variants
          as.matrix(
            find_trt_group[, current_state[1:(patnum - 1)] == arms[x]]
          ), 1, sum
        )
      })

      imbalance <- sapply(1:no_of_trt, function(x) {
        tmp <- n_duplicate_trt_group
        tmp[, x] <- tmp[, x] + 1
        num_lvl <- tmp %*% diag(1 / ratio)
        imb_margin <- apply(num_lvl, 1, get(method)) # switch range, sd, var
        if (method == "range") {
          imb_margin <- imb_margin[2, ] - imb_margin[1, ]
        }
        sum(weights %*% imb_margin)
      })
    }

    high_prob <- arms[which.min(imbalance)] # trt_mini
    low_prob <- arms[-high_prob]

    res <-
      if (length(high_prob) < no_of_trt) {
        res <-
          sample(c(high_prob, low_prob), 1,
            prob = c(
              rep(p / length(high_prob), length(high_prob)),
              rep(
                (1 - p) / length(low_prob),
                length(low_prob)
              )
            )
          )
      } else {
        res <-
          sample(arms, 1, prob = rep(1 / no_of_trt, no_of_trt))
      }
    return(res)
  }
