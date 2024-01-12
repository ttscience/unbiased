#* Initialize a study with Pocock's minimisation randomization
#*
#* Set up a new study for randomization defining it's parameters
#*
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
  validation_errors <- vector()

  err <- checkmate::check_character(name, min.chars = 1, max.chars = 255)
  if (err != TRUE) {
    validation_errors <- append_error(
      validation_errors, "name", err
    )
  }

  err <- checkmate::check_character(identifier, min.chars = 1, max.chars = 12)
  if (err != TRUE) {
    validation_errors <- append_error(
      validation_errors,
      "identifier",
      err
    )
  }

  err <- checkmate::check_choice(method, choices = c("range", "var", "sd"))
  if (err != TRUE) {
    validation_errors <- append_error(
      validation_errors,
      "method",
      err
    )
  }

  err <-
    checkmate::check_list(
      arms,
      types = "integerish",
      any.missing = FALSE,
      min.len = 2,
      names = "unique"
    )
  if (err != TRUE) {
    validation_errors <- append_error(
      validation_errors,
      "arms",
      err
    )
  }

  err <-
    checkmate::check_list(
      covariates,
      types = c("numeric", "list", "character"),
      any.missing = FALSE,
      min.len = 2,
      names = "unique"
    )
  if (err != TRUE) {
    validation_errors <-
      append_error(validation_errors, "covariates", err)
  }

  response <- list()
  for (c_name in names(covariates)) {
    c_content <- covariates[[c_name]]

    err <- checkmate::check_list(
      c_content,
      any.missing = FALSE,
      len = 2,
    )
    if (err != TRUE) {
      validation_errors <-
        append_error(
          validation_errors,
          glue::glue("covariates[{c_name}]"),
          err
        )
    }
    err <- checkmate::check_names(
      names(c_content),
      permutation.of = c("weight", "levels"),
    )
    if (err != TRUE) {
      validation_errors <-
        append_error(
          validation_errors,
          glue::glue("covariates[{c_name}]"),
          err
        )
    }

    # check covariate weight
    err <- checkmate::check_numeric(c_content$weight,
      lower = 0,
      finite = TRUE,
      len = 1,
      null.ok = FALSE
    )
    if (err != TRUE) {
      validation_errors <-
        append_error(
          validation_errors,
          glue::glue("covariates[{c_name}][weight]"),
          err
        )
    }

    err <- checkmate::check_character(c_content$levels,
      min.chars = 1,
      min.len = 2,
      unique = TRUE
    )
    if (err != TRUE) {
      validation_errors <-
        append_error(
          validation_errors,
          glue::glue("covariates[{c_name}][levels]"),
          err
        )
    }
  }

  # check probability
  p <- as.numeric(p)
  err <- checkmate::check_numeric(p, lower = 0, upper = 1, len = 1)
  if (err != TRUE) {
    validation_errors <-
      append_error(
        validation_errors,
        "p",
        err
      )
  }

  if (length(validation_errors) > 0) {
    res$status <- 400
    return(list(
      error = "Input validation failed",
      validation_errors = validation_errors
    ))
  }

  similar_studies <- get_similar_studies(name, identifier)

  strata <- purrr::imap(covariates, function(covariate, name) {
    list(
      name = name,
      levels = covariate$levels,
      value_type = "factor"
    )
  })
  weights <- lapply(covariates, function(covariate) covariate$weight)

  # Write study to DB -------------------------------------------------------
  r <- create_study(
    name = name,
    identifier = identifier,
    method = "minimisation_pocock",
    parameters = list(
      method = method,
      p = p,
      weights = weights
    ),
    arms = arms,
    strata = strata
  )

  # Response ----------------------------------------------------------------

  if (!is.null(r$error)) {
    res$status <- 409
    return(list(
      error = "There was a problem creating the study",
      details = r$error
    ))
  }

  response <- list(
    study = r$study
  )
  if (nrow(similar_studies) >= 1) {
    response <- c(response, list(similar_studies = similar_studies))
  }

  return(response)
}
