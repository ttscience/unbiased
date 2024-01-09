#* Initialize a study with Pocock's minimisation randomization
#*
#* Set up a new study for randomization defining it's parameters
#*
#* @param identifier:str Study code, at most 12 characters.
#* @param name:str Full study name.
#* @param method:str Function used to compute within-arm variability, must be one of: sd, var, range, defaults to var
#* @param arms:object Arm names (character) with their ratios (integer).
#* @param covariates:object Covariate names (character), allowed levels (character) and covariate weights (double).
#*
#* @tag initialize
#*
#* @post /minimisation_pocock
#* @serializer unboxedJSON
function(identifier, name, method, arms, covariates, req, res) {
  # assert connection with DB
  checkmate::assert(DBI::dbIsValid(CONN), .var.name = "DB connection")
  # check if study exists
  browser()
  dplyr::tbl(CONN, "study") |>
    dplyr::filter(name == "name" | identifier == "TEST")
  # return error if study already exists

  # validate request details
  assert_string(name)
  assert_string(identifier, max.chars = 12)

  assert_character(
    arms, min.chars = 1, any.missing = FALSE, min.len = 2, unique = TRUE
  )
  assert_integerish(ratio, lower = 0, any.missing = FALSE, len = length(arms))

  assert_list(strata, names = "unique", any.missing = FALSE)
  purrr::walk(strata, function(stratum) {
    # TODO: when allowing numeric strata, change the assertions here
    assert_character(
      stratum, min.chars = 1, any.missing = FALSE, min.len = 2, unique = TRUE
    )
  })
}
