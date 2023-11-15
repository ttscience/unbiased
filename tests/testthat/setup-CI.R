is_CI <- function() {
  isTRUE(as.logical(Sys.getenv("CI")))
}
