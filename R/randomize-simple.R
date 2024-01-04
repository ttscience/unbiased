#' Simple randomization
#'
#' @description
#' Randomly assigns a patient to one of the arms according to specified ratios,
#' regardless of already performed assignments.
#'
#' @param arms `character()`\cr
#'        Arm names.
#' @param ratio `integer()`\cr
#'        Vector of positive integers (0 is allowed), equal in length to number
#'        of arms, named after arms, defaults to equal weight
#'
#' @return Selected arm assignment.
#'
#' @examples
#' randomize_simple(c("active", "placebo"), c(2, 1))
#'
#' @export
randomize_simple <- function(arms, ratio) {
  # Validate argument presence and revert to defaults if not provided
  if (rlang::is_missing(ratio)) {
    ratio <- rep(1L, rep(length(arms)))
    names(ratio) <- arms
  }

  # Argument assertions
  assert_character(
    arms,
    any.missing = FALSE,
    unique = TRUE,
    min.chars = 1)

  assert_integer(
    ratio,
    any.missing = FALSE,
    lower = 0,
    len = length(arms),
    names = "named"
  )
  assert_names(
    names(ratio),
    must.include = arms
  )

  sample(arms, 1, prob = ratio[arms])
}
