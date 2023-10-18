api_url <- "http://api:3838"

skip_on_ci()

# Overwrite API URL if not on CI
api_url <- "http://127.0.0.1:5556"
api_path <- tempdir()

# Start the API
api <- callr::r_bg(\(path) {
  # 1. Set path to `path`
  # 2. Build a plumber API
  plumber::plumb(dir = "api") |>
    plumber::pr_run(port = 5556)
}, args = list(path = api_path))

# Wait until started
while (!api$is_alive()) {
  Sys.sleep(.2)
}

# Close API upon exiting
withr::defer({ api$kill() }, teardown_env())
