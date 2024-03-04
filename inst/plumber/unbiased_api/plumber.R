#* @apiTitle Unbiased
#* @apiDescription This API provides a diverse range of randomization
#*   algorithms specifically designed for use in clinical trials. It supports
#*   dynamic strategies such as the minimization method, as well as simpler
#*   approaches including standard and block randomization. The main goal of
#*   this API is to ensure seamless integration with electronic Case Report
#*   Form (eCRF) systems, facilitating efficient patient allocation management
#*   in clinical trials.
#* @apiContact list(name = "GitHub",
#*   url = "https://ttscience.github.io/unbiased/")
#* @apiLicense list(name = "MIT",
#*   url = "https://github.com/ttscience/unbiased/LICENSE.md")
#* @apiVersion 0.0.0.9003
#* @apiTag initialize Endpoints that initialize study with chosen
#*   randomization method and parameters.
#* @apiTag randomize Endpoints that randomize individual patients after the
#*   study was created.
#* @apiTag read Endpoints that read created records
#* @apiTag other Other endpoints (helpers etc.).
#*
#* @plumber
function(api) {
  meta <- plumber::pr("meta.R")
  study <- plumber::pr("study.R")

  meta |>
    plumber::pr_set_error(unbiased:::default_error_handler)

  study |>
    plumber::pr_set_error(unbiased:::default_error_handler)

  api |>
    plumber::pr_set_error(unbiased:::default_error_handler) |>
    unbiased:::setup_invalid_json_handler()

  api |>
    plumber::pr_mount("/meta", meta) |>
    plumber::pr_mount("/study", study) |>
    unbiased:::setup_audit_trail(endpoints = list(
      "^/study.*"
    )) |>
    plumber::pr_set_api_spec(function(spec) {
      spec$
        paths$
        `/study/minimisation_pocock`$
        post$requestBody$
        content$`application/json`$schema$properties$
        arms$example <- list("placebo" = 1, "active" = 1)
      spec$
        paths$
        `/study/minimisation_pocock`$
        post$requestBody$
        content$`application/json`$schema$properties$
        identifier$example <- "CSN"
      spec$
        paths$
        `/study/minimisation_pocock`$
        post$requestBody$
        content$`application/json`$schema$properties$
        p$example <- 0.85
      spec$
        paths$`/study/minimisation_pocock`$
        post$requestBody$
        content$`application/json`$
        schema$properties$
        name$example <- "Clinical Study Name"
      spec$
        paths$`/study/minimisation_pocock`$
        post$requestBody$
        content$`application/json`$
        schema$properties$
        method$example <- "range"
      # example of how to define covariates in minimisation pocock
      spec$
        paths$`/study/minimisation_pocock`$
        post$requestBody$
        content$`application/json`$
        schema$properties$
        covariates$example <-
        list(
          sex = list(
            weight = 1,
            levels = c("female", "male")
          ),
          weight = list(
            weight = 1,
            levels = c("up to 60kg", "61-80 kg", "81 kg or more")
          )
        )
      spec$
        paths$`/study/{study_id}/patient`$
        post$requestBody$content$`application/json`$
        schema$properties$current_state$example <-
        tibble::tibble(
          "sex" = c("female", "male"),
          "weight" = c("61-80 kg", "81 kg or more"),
          "arm" = c("placebo", "")
        )
      spec
    })
}


#* Log request data
#*
#* @filter logger
function(req) {
  cat(
    "[QUERY]",
    req$REQUEST_METHOD, req$PATH_INFO,
    "@", req$REMOTE_ADDR, "\n"
  )

  plumber::forward()
}
