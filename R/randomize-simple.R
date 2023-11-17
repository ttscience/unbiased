#' Simple randomization
#'
#' @description
#' Randomly assigns a patient to one of the arms according to specified ratios,
#' regardless of already performed assignments.
#'
#' @param arms `character()`\cr
#'  Arm names.
#' @param ratio `numeric()`\cr
#'  Ratio of patient assignment to each arm. Must be the same length as `arms`.
#'
#' @return Selected arm assignment.
#'
#' @examples
#' randomize_simple(c("active", "placebo"), c(2, 1))
#'
#' @export
randomize_simple <- function(arms, ratio) {
  assert_character(arms, any.missing = FALSE, unique = TRUE, min.chars = 1)
  assert_numeric(
    ratio, any.missing = FALSE, lower = 0, finite = TRUE, len = length(arms)
  )

  sample(arms, 1, prob = ratio)
}
