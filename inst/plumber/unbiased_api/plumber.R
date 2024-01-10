#* @plumber
function(api) {
  meta <- plumber::pr("meta.R")
  randomization_patient <- plumber::pr("randomization_patient.R")

  api |>
    plumber::pr_mount("/meta", meta) |>
    plumber::pr_mount("/study/patient", randomization_patient) |>
    plumber::pr_set_api_spec(function(spec) {

      # example of how to define arms
      spec$paths$`/study/patient/study/{study_id}/patient`$post$requestBody$content$`application/json`$schema$properties$current_state$example <-
        tibble::tibble("gender" = c("female", "male"),
                   "arm" = c("placebo", ""))

      spec
    })
}



