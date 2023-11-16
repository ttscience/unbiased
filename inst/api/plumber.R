#* @plumber
function(api) {
  meta <- plumber::pr("meta.R")

  api |>
    plumber::pr_mount("/meta", meta)
}

#* Randomize one patient
#*
#* @param strata:object
#*
#* @get /study/<study_id:chr>/randomize
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

#* Return hello world
#*
#* @get /simple/hello
#* @serializer unboxedJSON
function() {
  unbiased:::call_hello_world()
}
