#* Randomize one patient
#*
#*
#* @param study_id:int Study identifier
#* @param current_state:object
#*
#* @tag randomize
#* @post /study/<study_id:int>/patient
#* @serializer unboxedJSON
#*

function(study_id, current_state, req, res) {
  # Assertion connection with DB
  checkmate::assert(DBI::dbIsValid(db_connection_pool), .var.name = "DB connection")


  # Check whether study with study_id exists
  checkmate::expect_subset(x = req$args$study_id,
                           choices =
                             dplyr::tbl(db_connection_pool, "study") |>
                             dplyr::select(id) |>
                             dplyr::pull())

  #DF validation - error handling

  # Retrieve study details, especially the ones about randomization
  method_randomization <-
    dplyr::tbl(db_connection_pool, "study") |>
    dplyr::filter(id == study_id) |>
    dplyr::select(method) |>
    dplyr::pull()

  # asercja jeden element

  # Dispatch based on randomization method to parse parameters
  params <-
    switch(
      method_randomization,
      minimisation_pocock = tryCatch({
        do.call(unbiased:::parse_pocock_parameters, list(db_connection_pool, study_id, current_state))
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
      # browser()
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

  save_patient(study_id, arm$arm_id) |>
    dplyr::mutate(arm_name = arm$name) |>
    rename(patient_id = id) |>
    as.list()
}

