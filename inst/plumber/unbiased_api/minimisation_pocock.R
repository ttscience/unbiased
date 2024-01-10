#* Initialize a study with Pocock's minimisation randomization
#*
#* Set up a new study for randomization defining it's parameters
#*
#* @param identifier:str Study code, at most 12 characters.
#* @param name:str Full study name.
#* @param method:str Function used to compute within-arm variability, must be one of: sd, var, range
#* @param p:dbl Proportion of randomness (0, 1) in the randomization vs determinism (e.g. 0.85 equals 85% deterministic)
#* @param arms:object Arm names (character) with their ratios (integer).
#* @param covariates:object Covariate names (character), allowed levels (character) and covariate weights (double).
#*
#* @tag initialize
#*
#* @post /minimisation_pocock
#* @serializer unboxedJSON
#*
function(identifier, name, method, arms, covariates, p, req, res) {
  response <- list()
  # Assert DB connectivity --------------------------------------------------
  checkmate::assert(DBI::dbIsValid(CONN), .var.name = "DB connection")

  # Check if study exists ---------------------------------------------------
  similar <-
    dplyr::tbl(CONN, "study") |>
    dplyr::select(id, name, identifier) |>
    dplyr::filter(name == !!name | identifier == !!identifier) |>
    dplyr::collect()
  if (nrow(similar) >= 1) {
    response <- c(response, list(similar_studies = similar))
  }
  # Validate inputs ---------------------------------------------------------
  # study name no longer than 255 characters
  if (!checkmate::test_character(name, min.chars = 1, max.chars = 255)) {
    message <- checkmate::check_character(name, max.chars = 255)
    res$status <- 400
    res$body <-
      c(
        response,
        list(
          error = glue::glue("Input validation failed for 'name': {message}")
        )
      )
    return(res)
  }
  if (!checkmate::test_character(identifier, min.chars = 1, max.chars = 12)) {
    message <- checkmate::check_character(identifier, max.chars = 12)
    res$status <- 400
    res$body <-
      c(
        response,
        list(
          error = glue::glue("Input validation failed for 'identifier': {message}")
        )
      )
    return(res)
  }
  if (!checkmate::test_choice(method, choices = c("range", "var", "sd"))) {
    message <-
      checkmate::check_choice(
        method,
        choices = c("range", "var", "sd")
      )
    res$status <- 400
    res$body <-
      c(
        response,
        list(
          error = glue::glue("Input validation failed for 'method': {message}")
        )
      )
    return(res)
  }
  if (!checkmate::test_list(arms,
    types = "integerish",
    any.missing = FALSE,
    min.len = 2,
    names = "unique"
  )) {
    message <-
      checkmate::check_list(arms,
        types = "integerish",
        any.missing = FALSE,
        min.len = 2,
        names = "unique"
      )
    res$status <- 400
    res$body <-
      c(
        response,
        list(
          error = glue::glue("Input validation failed for 'arms': {message}")
        )
      )
    return(res)
  }
  if (!checkmate::test_list(covariates,
                            types = c("numeric", "list", "character"),
                            any.missing = FALSE,
                            min.len = 2,
                            names = "unique"
  )) {
    message <-
      checkmate::check_list(covariates,
                            types = c("numeric", "list", "character"),
                            any.missing = FALSE,
                            min.len = 1,
                            names = "unique"
      )
    res$status <- 400
    res$body <-
      c(
        response,
        list(
          error = glue::glue("Input validation failed for 'covariates': {message}")
        )
      )
    return(res)
  }
  # check all covariates
  purrr::walk2(covariates, names(covariates), function(c_content, c_name) {
    if (length(c_content) != 2) {
      res$status <- 400
      res$body <-
        c(
          response,
          list(
            error =
              glue::glue("Covariate '{c_name}' has {length(c_content)} elements while 2 were expected")
          )
        )
      return(res)
    }
    # check covariate properties names
    if (!all(names(c_content) == c("weight", "levels"))) {
      res$status <- 400
      res$body <-
        c(
          response,
          list(
            error =
              glue::glue("Covariate '{c_name}' has elements named different than 'weight' and 'levels'")
          )
        )
      return(res)
    }
    if (!checkmate::test_numeric(c_content$weight,
                                 lower = 0,
                                 finite = TRUE,
                                 len = 1,
                                 null.ok = FALSE)) {
      message <-
        checkmate::check_numeric(c_content$weight,
                                 lower = 0,
                                 finite = TRUE,
                                 len = 1,
                                 null.ok = FALSE)
      res$status <- 400
      res$body <-
        c(
          response,
          list(
            error = glue::glue("Input validation failed for covariate '{c_name}', weight: {message}")
          )
        )
      return(res)
    }
    if (!checkmate::test_character(c_content$levels,
                                   min.chars = 1,
                                   min.len = 2,
                                   unique = TRUE)) {
      message <-
        checkmate::check_character(c_content$levels,
                                   min.chars = 1,
                                   min.len = 2,
                                   unique = TRUE)
      res$status <- 400
      res$body <-
        c(
          response,
          list(
            error = glue::glue("Input validation failed for covariate '{c_name}', levels: {message}")
          )
        )
      return(res)
    }
  })
  # check probability
  p <- as.numeric(p)
  if (!checkmate::test_numeric(p, lower = 0, upper = 1, len = 1)) {
    message <-
      checkmate::check_numeric(p, lower = 0, upper = 1, len = 1)
    res$status <- 400
    res$body <-
      c(
        response,
        list(
          error = glue::glue("Input validation failed for 'p': {message}")
        )
      )
    return(res)
  }

  # Write study to DB -------------------------------------------------------

  # Response ----------------------------------------------------------------

  return(response)
}




