#' Parse parameters for Pocock randomization method
#'
#' Function to parse and process parameters for the Pocock randomization method.
#'
#' @return params List of parameters


parse_pocock_parameters <- function(CONN, study_id, current_state){
  parameters <- tbl(CONN, "study") |>
    filter(study_id == study_id) |>
    select(parameters) |>
    pull()

  parameters <- jsonlite::fromJSON(parameters)

  # do testowania
  # parameters <- jsonlite::fromJSON('{"method": "var", "p": 0.85, "weights": {"gender": 1, "age_group" : 2, "height" : 1}}')

  ratio_arms = tbl(CONN, "arm") |>
    filter(study_id == study_id) |>
    select(name, ratio) |>
    collect()

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
