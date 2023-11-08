# objects to save for dynamic randomization
to_save <- c("trial", "study_name", "N", "arm_names", "arm_ratios", "centers", "pIDs", "strata", "study_path", "patient_data")

print_log <- function(...) {
  cat(as.character(Sys.time()), "-", ..., "\n")
}

library(dplyr)
library(stringr)
library(tibble)
library(tidyr)
# convert S4 class to a dataframe
S4_to_dataframe <- function(mypatients) {
  
  if(!is.null(mypatients)){
    lapply(1:length(mypatients), function(mys4){
      names <- slotNames(mypatients[[mys4]])
      
      lt <- lapply(names, function(names) slot(mypatients[[mys4]], names))
      lt <- setNames(lt, names)
      
      lt %>%
        unlist(recursive = FALSE) %>%
        enframe() %>%
        spread(name, value) %>%
        unnest(cols = names(.)) %>%
        mutate(date = as.Date(date, origin="1970-01-01"))
    }) %>%
      bind_rows()
  } else {
    return(NULL)
  }
}

TTSIminimizeTaves <- function(df, features, trtvec, obsdf, trttab){
  picks <- randPack:::factorCounts(df, features, trtvec, obsdf)
  picks <- vapply(picks, base::sum, FUN.VALUE = integer(1L))
  missing_picks <- setdiff(names(trttab), names(picks))
  additional_picks <- integer(length(missing_picks))
  names(additional_picks) <- missing_picks
  picks <- c(picks, additional_picks)
  picks <- picks[picks == min(picks)]
  return(sample(x = names(picks), size = 1L, prob = trttab[names(picks)]))
}