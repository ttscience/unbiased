dirs <- list.dirs(recursive = FALSE)
if (!any(dirs == "./studies")) {
  dir.create("studies")
}

source("helpers.R")

#* @filter Log request
function(req){
  print_log(req$REQUEST_METHOD, req$PATH_INFO)
  plumber::forward()
}

#* @plumber

function(api) {
  rand_simple <- plumber::pr("randomize-simple.R")
  rand_block <- plumber::pr("randomize-block.R")
  meta <- plumber::pr("meta.R")
  
  api |>
    plumber::pr_mount("/simple", rand_simple) |>
    plumber::pr_mount("/block", rand_block) |> 
    plumber::pr_mount("/meta", meta) 
}
