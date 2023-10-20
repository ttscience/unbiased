#* @plumber
function(api) {
  rand_simple <- plumber::pr("randomize-simple.R")
  meta <- plumber::pr("meta.R")
  
  api |>
    plumber::pr_mount("/simple", rand_simple) |>
    plumber::pr_mount("/meta", meta)
}
