# Start the API
api_path <- tempdir()
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
