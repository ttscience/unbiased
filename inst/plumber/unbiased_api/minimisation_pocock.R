#* Initialize a study with Pocock's minimisation randomization
#*
#* Set up a new study for randomization defining it's parameters
#*
#*
#* @param identifier:object Study code, at most 12 characters.
#* @param name:object Full study name.
#* @param method:object Function used to compute within-arm variability, must be one of: sd, var, range
#* @param p:object Proportion of randomness (0, 1) in the randomization vs determinism (e.g. 0.85 equals 85% deterministic)
#* @param arms:object Arm names (character) with their ratios (integer).
#* @param covariates:object Covariate names (character), allowed levels (character) and covariate weights (double).
#*
#* @tag initialize
#*
#* @post /minimisation_pocock
#* @serializer unboxedJSON
#*
function(identifier, name, method, arms, covariates, p, req, res) {
  source("study-repository.R")
  source("validation-utils.R")
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
                    add = collection)

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
    add = collection)

    checkmate::assert(
      checkmate::check_names(
      names(c_content),
      permutation.of = c("weight", "levels"),
    ),
    .var.name = "covariates2",
    add = collection)

    # check covariate weight
    checkmate::assert(
      checkmate::check_numeric(c_content$weight,
                                    lower = 0,
                                    finite = TRUE,
                                    len = 1,
                                    null.ok = FALSE
    ),
    .var.name = "weight",
    add = collection)

    checkmate::assert(
      checkmate::check_character(c_content$levels,
                                      min.chars = 1,
                                      min.len = 2,
                                      unique = TRUE
    ),
    .var.name = "levels",
    add = collection)
  }

  # check probability
  checkmate::assert(
    checkmate::check_numeric(p, lower = 0, upper = 1, len = 1,
                             any.missing = FALSE, null.ok = FALSE),
    .var.name = "p",
    add = collection)


  if (length(collection$getMessages()) > 0) {
    res$status <- 400
    return(list(
      error = "There was a problem with the input data to create the study",
      validation_errors = collection$getMessages()
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
    res$status <- 503
    return(list(
      error = "There was a problem saving created study to the database",
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


#* Randomize one patient
#*
#*
#* @param study_id:int Study identifier
#* @param current_state:object
#*
#* @tag randomize
#* @post /<study_id:int>/patient
#* @serializer unboxedJSON
#*

function(study_id, current_state, req, res) {
  collection <- checkmate::makeAssertCollection()

  # Check whether study with study_id exists
  checkmate::assert(checkmate::check_subset(x = req$args$study_id,
                                            choices =
                                              dplyr::tbl(db_connection_pool, "study") |>
                                              dplyr::select(id) |>
                                              dplyr::pull()),
                    .var.name = "study_id",
                    add = collection)

  # Retrieve study details, especially the ones about randomization
  method_randomization <-
    dplyr::tbl(db_connection_pool, "study") |>
    dplyr::filter(id == study_id) |>
    dplyr::select(method) |>
    dplyr::pull()

  checkmate::assert(
    checkmate::check_scalar(method_randomization, null.ok = FALSE),
                    .var.name = "method_randomization",
                    add = collection)

  if (length(collection$getMessages()) > 0) {
    res$status <- 400
    return(list(
      error = "There was a problem with the randomization preparation",
      validation_errors = collection$getMessages()
    ))
  }

  # Dispatch based on randomization method to parse parameters
  source("parse_pocock.R")
  params <-
    switch(
      method_randomization,
      minimisation_pocock = do.call(parse_pocock_parameters, list(db_connection_pool, study_id, current_state))
    )

  arm_name <-
    switch(
      method_randomization,
      # simple = do.call(unbiased:::randomize_simple, params),
      minimisation_pocock = do.call(unbiased:::randomize_minimisation_pocock, params)
    )

  arm <- dplyr::tbl(db_connection_pool, "arm") |>
    dplyr::filter(study_id == !!study_id & name == arm_name) |>
    dplyr::select(arm_id = id, name, ratio) |>
    dplyr::collect()

  randomized_patient <- save_patient(study_id, arm$arm_id)

  if (!is.null(randomized_patient$error)) {
    res$status <- 503
    return(list(
      error = "There was a problem saving randomized patient to the database",
      details = randomized_patient$error
    ))
  } else {
    randomized_patient <-
      randomized_patient |>
      dplyr::mutate(arm_name = arm$name) |>
      dplyr::rename(patient_id = id) |>
      as.list()

    return(randomized_patient)
  }
}


