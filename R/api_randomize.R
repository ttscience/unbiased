api__randomize_patient <- function(study_id, current_state, req, res) {
  collection <- checkmate::makeAssertCollection()
 
  # Check whether study with study_id exists
  checkmate::assert(checkmate::check_subset(x = req$args$study_id,
                           choices =
                             dplyr::tbl(db_connection_pool, "study") |>
                             dplyr::select(id) |>
                             dplyr::pull()), .var.name = "Study ID",
                    add = collection)

  # Retrieve study details, especially the ones about randomization
  method_randomization <-
    dplyr::tbl(db_connection_pool, "study") |>
    dplyr::filter(id == study_id) |>
    dplyr::select(method) |>
    dplyr::pull()

  checkmate::assert(checkmate::check_scalar(method_randomization, null.ok = FALSE),
                    .var.name = "Randomization method",
                    add = collection)

  if (length(collection$getMessages()) > 0) {
    res$status <- 400
    return(list(
      error = "Study input validation failed",
      validation_errors = collection$getMessages()
    ))
  }

  # Dispatch based on randomization method to parse parameters
  params <-
    switch(
      method_randomization,
      minimisation_pocock = tryCatch({
        do.call(parse_pocock_parameters, list(db_connection_pool, study_id, current_state))
      }, error = function(e) {
        res$status <- 400
        res$body = glue::glue("Error message: {conditionMessage(e)}")
        logger::log_error("Error: {err}", err=e)
      })
    )

  arm_name <-
    switch(
      method_randomization,
      # simple = do.call(unbiased:::randomize_simple, params),
      minimisation_pocock = tryCatch({
        do.call(unbiased:::randomize_minimisation_pocock, params)
      }, error = function(e) {
        res$status <- 400
        res$body = glue::glue("Error message: {conditionMessage(e)}")
        logger::log_error("Error: {err}", err=e)
      }
      )
    )

  arm <- dplyr::tbl(db_connection_pool, "arm") |>
    dplyr::filter(study_id == !!study_id & name == arm_name) |>
    dplyr::select(arm_id = id, name, ratio) |>
    dplyr::collect()

  unbiased:::save_patient(study_id, arm$arm_id) |>
      dplyr::mutate(arm_name = arm$name) |>
      dplyr::rename(patient_id = id) |>
      as.list()
}

parse_pocock_parameters <- function(db_connetion_pool, study_id, current_state){
  parameters <-
    dplyr::tbl(db_connetion_pool, "study") |>
    dplyr::filter(id == study_id) |>
    dplyr::select(parameters) |>
    dplyr::pull()

  parameters <- jsonlite::fromJSON(parameters)

  if (!checkmate::test_list(parameters, null.ok = FALSE)){
    message <- checkmate::test_list(parameters,  null.ok = FALSE)
    res$status <- 400
    res$body <-
      c(
        response,
        list(
          error = glue::glue("Parse validation failed. 'Parameters' must be a list: {message}")
        )
      )
    return(res)
  }

  # do testowania
  # parameters <- jsonlite::fromJSON('{"method": "var", "p": 0.85, "weights": {"gender": 1, "age_group" : 2, "height" : 1}}')

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

  if (!checkmate::test_list(params,  null.ok = FALSE)){
    message <- checkmate::test_list(params,  null.ok = FALSE)
    res$status <- 400
    res$body <-
      c(
        response,
        list(
          error = glue::glue("Parse validation failed. Input parameters must be a list: {message}")
        )
      )
    return(res)
  }

  return(params)
}
