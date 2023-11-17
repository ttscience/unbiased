if (is_CI()) {
  # Define connection ----
  conn <- connect_to_db()

  # Close DB connection upon exiting
  withr::defer({ DBI::dbDisconnect(conn) }, teardown_env())
}
