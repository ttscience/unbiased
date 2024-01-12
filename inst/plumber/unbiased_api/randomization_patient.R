#* Randomize one patient
#*
#*
#* @param study_id:int Study identifier
#* @param current_state:object
#*
#* @tag randomize
#* @post /study/<study_id:int>/patient
function(study_id, current_state, req, res) {

  # Assertion connection with DB
  checkmate::assert(DBI::dbIsValid(CONN), .var.name = "DB connection")

  # Check whether study with study_id exists
  checkmate::expect_subset(x =
                             dplyr::tbl(CONN, "study") |>
                             dplyr::select(id) |>
                             dplyr::pull(),
                           choices = req$args$study_id)

  #DF validation - error handling

  # Retrieve study details, especially the ones about randomization
  method_randomization <-
    dplyr::tbl(CONN, "study") |>
    dplyr::filter(study_id == study_id) |>
    dplyr::select(method) |>
    dplyr::pull()

  # Dispatch based on randomization method to parse parameters
  params <-
    switch(
      method_randomization,
      # simple = do.call(unbiased:::parse_simple_randomization, list(CONN, study_id, current_state)),
      minimisation_pocock = tryCatch({
        do.call(unbiased:::parse_pocock_parameters, list(CONN, study_id, current_state))
      }, error = function(e) {
        res$status <- 400
        res$body = glue::glue("Error message: {conditionMessage(e)}")
      })
    )

  switch(
    method_randomization,
    # simple = do.call(unbiased:::randomize_simple, params),
    minimisation_pocock = tryCatch({
      do.call(unbiased:::randomize_minimisation_pocock, params)
    }, error = function(e) {
      # browser()
      res$status <- 400
      res$body = glue::glue("Error message: {conditionMessage(e)}")
    }
    )
  )
}

