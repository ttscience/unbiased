#* @plumber
function(api) {
  rand_simple <- plumber::pr("randomize-simple.R")
  
  api |>
    plumber::pr_mount("/simple", rand_simple)
}
