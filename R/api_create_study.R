api__minimization_pocock <- function(
    # nolint: cyclocomp_linter.
    identifier, name, method, arms, covariates, p, req, res) {
  audit_log_set_event_type("study_create", req)

  collection <- checkmate::makeAssertCollection()

  checkmate::assert(
    checkmate::check_character(name, min.chars = 1, max.chars = 255),
    .var.name = "name",
    add = collection
  )

  checkmate::assert(
    checkmate::check_character(identifier, min.chars = 1, max.chars = 12),
    .var.name = "identifier",
    add = collection
  )

  checkmate::assert(
    checkmate::check_choice(method, choices = c("range", "var", "sd")),
    .var.name = "method",
    add = collection
  )

  checkmate::assert(
    checkmate::check_list(
      arms,
      types = "integerish",
      any.missing = FALSE,
      min.len = 2,
      names = "unique"
    ),
    .var.name = "arms",
    add = collection
  )

  checkmate::assert(
    checkmate::check_list(
      covariates,
      types = c("numeric", "list", "character"),
      any.missing = FALSE,
      min.len = 1,
      names = "unique"
    ),
    .var.name = "covariates3",
    add = collection
  )

  response <- list()
  for (c_name in names(covariates)) {
    c_content <- covariates[[c_name]]

    checkmate::assert(
      checkmate::check_list(
        c_content,
        any.missing = FALSE,
        len = 2,
      ),
      .var.name = "covariates1",
      add = collection
    )

    checkmate::assert(
      checkmate::check_names(
        names(c_content),
        permutation.of = c("weight", "levels"),
      ),
      .var.name = "covariates2",
      add = collection
    )

    # check covariate weight
    checkmate::assert(
      checkmate::check_numeric(c_content$weight,
        lower = 0,
        finite = TRUE,
        len = 1,
        null.ok = FALSE
      ),
      .var.name = "weight",
      add = collection
    )

    checkmate::assert(
      checkmate::check_character(c_content$levels,
        min.chars = 1,
        min.len = 2,
        unique = TRUE
      ),
      .var.name = "levels",
      add = collection
    )
  }

  # check probability
  checkmate::assert(
    checkmate::check_numeric(p,
      lower = 0, upper = 1, len = 1,
      any.missing = FALSE, null.ok = FALSE
    ),
    .var.name = "p",
    add = collection
  )


  if (length(collection$getMessages()) > 0) {
    res$status <- 400
    return(list(
      error = "There was a problem with the input data to create the study",
      validation_errors = collection$getMessages()
    ))
  }

  similar_studies <- unbiased:::get_similar_studies(name, identifier)

  strata <- purrr::imap(covariates, function(covariate, name) {
    list(
      name = name,
      levels = covariate$levels,
      value_type = "factor"
    )
  })
  weights <- lapply(covariates, function(covariate) covariate$weight)

  # Write study to DB -------------------------------------------------------
  r <- unbiased:::create_study(
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

  audit_log_set_study_id(r$study$id, req)

  response <- list(
    study = r$study
  )
  if (nrow(similar_studies) >= 1) {
    response <- c(response, list(similar_studies = similar_studies))
  }

  return(response)
}
