parse_pocock_parameters <-
  function(db_connetion_pool, study_id, current_state) {
    parameters <-
      dplyr::tbl(db_connetion_pool, "study") |>
      dplyr::filter(id == study_id) |>
      dplyr::select(parameters) |>
      dplyr::pull()

    parameters <- jsonlite::fromJSON(parameters)

    ratio_arms <-
      dplyr::tbl(db_connetion_pool, "arm") |>
      dplyr::filter(study_id == !!study_id) |>
      dplyr::select(name, ratio) |>
      dplyr::collect()

    params <- list(
      arms = ratio_arms$name,
      current_state = tibble::as_tibble(current_state),
      ratio = setNames(ratio_arms$ratio, ratio_arms$name),
      method = parameters$method,
      p = parameters$p,
      weights = parameters$weights |> unlist()
    )

    return(params)
  }

api__randomize_patient <- function(study_id, current_state, req, res) {
  collection <- checkmate::makeAssertCollection()

  db_connection_pool <- get("db_connection_pool")

  study_id <- req$args$study_id

  is_study <-
    checkmate::test_true(
      dplyr::tbl(db_connection_pool, "study") |>
        dplyr::filter(id == study_id) |>
        dplyr::collect() |>
        nrow() > 0
    )

  if (!is_study) {
    res$status <- 404
    return(list(
      error = "Study not found"
    ))
  }

  # Retrieve study details, especially the ones about randomization
  method_randomization <-
    dplyr::tbl(db_connection_pool, "study") |>
    dplyr::filter(id == study_id) |>
    dplyr::select("method") |>
    dplyr::pull()

  checkmate::assert(
    checkmate::check_scalar(method_randomization, null.ok = FALSE),
    .var.name = "method_randomization",
    add = collection
  )

  if (length(collection$getMessages()) > 0) {
    res$status <- 400
    return(list(
      error = "There was a problem with the randomization preparation",
      validation_errors = collection$getMessages()
    ))
  }

  # Dispatch based on randomization method to parse parameters
  params <-
    switch(method_randomization,
      minimisation_pocock = do.call(
        parse_pocock_parameters, list(db_connection_pool, study_id, current_state)
      )
    )

  arm_name <-
    switch(method_randomization,
      minimisation_pocock = do.call(
        unbiased:::randomize_minimisation_pocock, params
      )
    )

  arm <- dplyr::tbl(db_connection_pool, "arm") |>
    dplyr::filter(study_id == !!study_id & .data$name == arm_name) |>
    dplyr::select("arm_id" = "id", "name", "ratio") |>
    dplyr::collect()

  randomized_patient <- unbiased:::save_patient(study_id, arm$arm_id)

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
