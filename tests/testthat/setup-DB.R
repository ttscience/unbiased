skip_if_not(is_CI(), "DB tests require complex setup through Docker Compose")

# Define connection ----
conn <- purrr::insistently(function() {
  DBI::dbConnect(
    RPostgres::Postgres(),
    dbname = "postgres",
    host = "postgres",
    port = 5432,
    user = "postgres",
    password = "postgres"
  )
}, rate = purrr::rate_delay(2, max_times = 5))()

# Close DB connection upon exiting
withr::defer({ DBI::dbDisconnect(conn) }, teardown_env())
