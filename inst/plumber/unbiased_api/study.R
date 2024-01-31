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
  return(
    unbiased:::api__create_study_minimization_pocock(
      identifier, name, method, arms, covariates, p, req, res
    )
  )
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
  return(
    unbiased:::api__randomize_patient(study_id, current_state, req, res)
  )
}
