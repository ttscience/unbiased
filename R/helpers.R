#' Compare rows of two dataframes
#'
#' Takes dataframe B (presumably with one row / patient) and compares it to all
#' rows of A (presumably already randomized patietns)
#'
#' @param A data.frame with all patients
#' @param B data.frame with new patient
#'
#' @return data.frame with columns as in A and B, filled with TRUE if there is
#'         match in covariate and FALSE if not
#'
#' @examples
compare_rows <- function(A, B) {
  # Find common column names
  common_cols <- intersect(names(A), names(B))

  # Compare each common column of A with B
  comparisons <- lapply(common_cols, function(col) {
    A[[col]] == B[[col]]
  })

  # Combine the comparisons into a new dataframe
  C <- data.frame(comparisons)
  names(C) <- common_cols
  tibble::as_tibble(C)
}
