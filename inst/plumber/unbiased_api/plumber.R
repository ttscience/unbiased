#* @plumber
function(api) {
  meta <- plumber::pr("meta.R")

  api |>
    plumber::pr_mount("/meta", meta)
}

#* Log request data
#*
#* @filter logger
function(req) {
  cat(
    "[QUERY]",
    req$REQUEST_METHOD, req$PATH_INFO,
    "@", req$REMOTE_ADDR, "\n"
  )
  purrr::imap(req$args, function(arg, arg_name) {
    cat("[ARG]", arg_name, "=", as.character(arg), "\n")
  })
  if (req$postBody != "") {
    cat("[BODY]", req$postBody, "\n")
  }

  plumber::forward()
}

#* Define study to randomize
#*
#* @param identifier:str Study code, at most 12 characters.
#* @param name:str Full study name.
#* @param method:str Randomization method to apply.
#* @param arms:[str] Arm names to use.
#* @param ratio:[int] Arm ratios, must be the same length as arm names.
#* @param strata:object List of character vectors, each list element being a stratum and each string being a possible stratum value. Could possibly take a numeric structure as well instead of a character vector, e.g. `{"min": 1, "max": 10}`. It just needs handling by checking whether the inner list is named or not, I'd say.
#* @param parameters:object Parameters to pass to randomization.
#*
#* @post /study
function(identifier, name, method, arms, ratio, strata, parameters, req, res) {
  # Coerce types (plumber doesn't do that)
  ratio <- as.integer(ratio)

  # Assertions


  # Define study
  unbiased:::define_study(
    name, identifier, arms, method,
    strata = strata, parameters = parameters, ratio = ratio
  )
}

#* Get available studies
#*
#* @get /study
function(req, res) {
  unbiased:::list_studies()
}

#* Get study details
#*
#* @get /study/<study_id:int>
function(study_id, req, res) {
  study_id <- as.integer(study_id)

  if (!unbiased:::study_exists(study_id)) {
    res$status <- 404
    return(list(error = glue::glue("Study {study_id} does not exist.")))
  }

  unbiased:::read_study_details(study_id)
}

#* Randomize one patient
#*
#* @param strata:object
#*
#* @post /study/<study_id:int>/randomize
function(strata, req, res) {
  # Check whether study with study_id exists, if not, return error

  # Retrieve study details, especially the ones about randomization
  method <- NULL
  params <- list(
    arms = character(),
    ratio = numeric()
  )

  # Assert that patient has the same strata as study
  #  and that patient's values are allowed in study

  # Dispatch based on randomization method
  switch(
    method,
    simple = do.call(unbiased:::randomize_simple, params),
    # block = do.call(unbiased:::randomize_blocked, c(params, strata = strata))
  )
}
