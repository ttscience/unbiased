skip_if_not(is_CI(), "DB tests require complex setup through Docker Compose")

# Define connection ----
conn <- connect_to_db()

# Close DB connection upon exiting
withr::defer({ DBI::dbDisconnect(conn) }, teardown_env())
