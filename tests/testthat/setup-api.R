api_url <- "http://api:3838"

if (!isTRUE(as.logical(Sys.getenv("CI")))) {
  withr::local_envvar(
    # Extract current SHA and set it as a temporary env var
    list(GITHUB_SHA = system("git rev-parse HEAD", intern = TRUE))
  )
  
  # Overwrite API URL if not on CI
  api_url <- "http://localhost:3838"
  api_path <- tempdir()
  
  # Start the API
  api <- callr::r_bg(\(path) {
    # 1. Set path to `path`
    # 2. Build a plumber API
    plumber::plumb(dir = fs::path("..", "..", "api")) |>
      plumber::pr_run(port = 3838)
  }, args = list(path = api_path))
  
  # Wait until started
  while (!api$is_alive()) {
    Sys.sleep(.2)
  }
  
  # Close API upon exiting
  withr::defer({ api$kill() }, teardown_env())
}
