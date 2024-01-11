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

  ratio_arms = tbl(CONN, "arm") |>
    filter(study_id == study_id) |>
    select(name, ratio) |>
    collect()

  params <- list(
    arms = ratio_arms$name,
    # current_state = tibble::as_tibble(current_state),
    current_state = current_state,
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
