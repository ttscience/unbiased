#* Block randomization, one-off.
#*
#' @post /<study_name>
#' @param study_name:character Name of the study
#' @param N:int Number of participants to (maximum) in a study
#' @param block:[int] Block sizes (array), typically small integers: e.g. 2, 4, 6, must be multiples of the sum of ratios (if ratio not specified, multiples of the number of arms instead).
#' @param strata:object Strata definition as JSON, e.g. {"strata":{"foo":["bar","baz"],"baz":["hip","hop"]}}. Optional, can also accept empty definition, i.e. {"strata":{}}.
#' @param arms:object Arms definition as JSON array, e.g. {"arms":["arm1","arm2"]}
#' @param ratio:object Frequency of each arm, e.g. {"ratio":[1,2]}. Optional.
#' @serializer unboxedJSON

function(study_name, N, arms, block, ratio, req, res) {
  print_log("query:", paste(names(unlist(req$argsQuery)), "=", unlist(req$argsQuery)))
  print_log("body:", req$postBody)
  
  randomized <- list.files("studies")
  
  if (study_name %in% randomized) {
    message <- paste("Study", study_name, "is already randomized")
    print_log("http 409:", message)
    res$status <- 409
    return(message)
  }
  
  # parse and validate inputs
  N <- as.integer(N)
  checkmate::assert_count(N, positive = TRUE)
  
  #validate JSON structure
  if(!jsonlite::validate(req$postBody)) {
    # not a valid JSON
    print_log("Invalid JSON structure, returning http 400")
    res$status <- 400
    validation_result <- jsonlite::validate(req$postBody)
    return(attributes(validation_result))
  }
  
  parsed_body <- jsonlite::fromJSON(req$postBody)
  if (is.null(parsed_body$strata)) {
    parsed_body$strata <- list()
  }
  if (length(parsed_body$strata) == 0) {
    # Adding names makes JSON converter use {} instead of []
    names(parsed_body$strata) <- character()
  }
  if (!all(c("strata", "arms") %in% names(parsed_body))) {
    print_log("Missing elements in JSON, returning http 400")
    res$status <- 400
    return("JSON must contain 'strata' and 'arms' elements.")
  }
  
  checkmate::assert_list(parsed_body,
                         any.missing = FALSE,
                         min.len = 1,
                         names = "strict")
  
  arms <- length(parsed_body$arms)
  arm_names <- parsed_body$arms
  checkmate::assert_count(arms, positive = TRUE)
  checkmate::assert(arms > 1, .var.name = "There should be at least two arms")
  checkmate::assert_true(length(arm_names) == length(unique(arm_names)), .var.name = "Arms must be unique")
  
  strata <- parsed_body$strata
  checkmate::assert_list(strata, any.missing = FALSE, names = "strict")
  lapply(strata, function(individual_strata) checkmate::assert_true(length(individual_strata)>1L, .var.name = "Each strata need at least two values"))
  lapply(strata, function(individual_strata) checkmate::assert_character(individual_strata, min.len = 1))
  lapply(strata, function(individual_strata) checkmate::assert_true(length(individual_strata) == length(unique(individual_strata)), .var.name = "Strata values must be unique"))
  checkmate::assert_false(any(c("name", "alloc", "allocation") %in% names(strata)), .var.name = "Strata name must be different than 'name', 'alloc' or 'allocation' for technical reasons")
  
  ratio <- parsed_body$ratio
  if (is.null(ratio)) {
    # Default value if none available
    ratio <- rep(1, arms)
  }
  ratio <- as.integer(ratio)
  checkmate::assert_integer(ratio, lower = 1, any.missing = FALSE)
  checkmate::assert_true(length(ratio) == arms, .var.name = "Arm and ratio lengths must be equal")
  
  block <- as.integer(block)
  checkmate::assert_integer(block, lower = 1, any.missing = FALSE)
  checkmate::assert(all(block %% sum(ratio) == 0))
  
  # randomize
  library(randomizeR)
  
  strata_grid <- if (length(strata) == 0) {
    tibble::tibble(.rows = 1)
  } else {
    tibble::as_tibble(expand.grid(strata, stringsAsFactors = FALSE))
  }
  strata_n <- nrow(strata_grid)
  
  # wygenerowanie sekwencji dla każdego stratum
  genSeq_list <- lapply(seq_len(strata_n), function(i) {
    rand <- rpbrPar(
      N = N, rb = block, K = arms, ratio = ratio,
      groups = arm_names, filledBlock = FALSE
    )
    getRandList(genSeq(rand))[1, ]
  })
  
  #stworzenie listy randomizacyjnej
  df_list = tibble::tibble()
  for(i in seq_len(strata_n)) {
    local_df <- strata_grid %>%
      dplyr::slice(i) %>%
      dplyr::mutate(count = N) %>%
      tidyr::uncount(count) %>%
      tibble::add_column(arm = genSeq_list[[i]])
    df_list <- rbind(local_df, df_list)
  }
  #przypisanie unikalnych kodow randomizacyjnych
  randomization_space <- nrow(df_list) * 3
  df_list$randomization_code <- sample(
    1:randomization_space, strata_n * N, replace=FALSE
  )
  df_list$randomization_code <- stringr::str_pad(
    string = df_list$randomization_code,
    width = max(nchar(as.character(df_list$randomization_code))),
    pad = 0
  )
  
  # save results
  study_path <- paste0("studies/", study_name)
  dir.create(study_path)
  file.create(paste0(study_path, "/T0block"))
  
  save(list = ls(all.names = TRUE),
       file = paste0(study_path, "/session_0.RData"),
       envir = environment(),
       ascii = TRUE,
       compress = T)
  
  readr::write_csv(df_list,
                   file =  paste0(study_path, "/randomization.csv"))
  
  return(df_list)
}