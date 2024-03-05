#* Initialize a study with Pocock's minimisation randomization
#*
#* Set up a new study for randomization defining its parameters
#*
#*
#* @param identifier:object Study code, at most 12 characters.
#* @param name:object Full study name.
#* @param method:object Function used to compute within-arm variability,
#*   must be one of: sd, var, range
#* @param p:object Proportion of randomness (0, 1) in the randomization vs
#*   determinism (e.g. 0.85 equals 85% deterministic)
#* @param arms:object Arm names (character) with their ratios (integer).
#* @param covariates:object Covariate names (character), allowed levels
#*   (character) and covariate weights (double).
#*
#* @tag initialize
#*
#* @post /minimisation_pocock
#* @serializer unboxedJSON
#*
unbiased:::wrap_endpoint(function(
    identifier, name, method, arms, covariates, p, req, res) {
  return(
    unbiased:::api__minimization_pocock(
      identifier, name, method, arms, covariates, p, req, res
    )
  )
})

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

unbiased:::wrap_endpoint(function(study_id, current_state, req, res) {
  return(
    unbiased:::api__randomize_patient(study_id, current_state, req, res)
  )
})


#* Get study audit log
#*
#* Get the audit log for a study
#*
#*
#* @param study_id:int Study identifier
#*
#* @tag audit
#* @get /<study_id:int>/audit
#* @serializer unboxedJSON
#*
unbiased:::wrap_endpoint(function(study_id, req, res) {
  return(
    unbiased:::api_get_audit_log(study_id, req, res)
  )
})


#* Get all available studies
#*
#* @return tibble with study_id, identifier, name and method
#*
#* @tag read
#* @get /
#* @serializer unboxedJSON
#*

unbiased:::wrap_endpoint(function(req, res) {
  return(
    unbiased:::api_get_study(req, res)
  )
})

#* Get all records for chosen study
#*
#* @param study_id:int Study identifier
#*
#* @tag read
#* @get /<study_id:int>
#*
#* @serializer unboxedJSON
#*

unbiased:::wrap_endpoint(function(study_id, req, res) {
  return(
    unbiased:::api_get_study_records(study_id, req, res)
  )
})

#* Get randomization list
#*
#* @param study_id:int Study identifier
#*
#* @tag read
#* @get /<study_id:int>/randomization_list
#* @serializer unboxedJSON
#*

unbiased:::wrap_endpoint(function(study_id, req, res) {
  return(
    unbiased:::api_get_rand_list(study_id, req, res)
  )
})
