if (is_CI()) {
  # Define connection ----
  db_pool <- create_db_connection_pool()
  conn <- pool::poolCheckout(db_pool)

  # Close DB connection upon exiting
  withr::defer(
    {
      pool::poolReturn(conn)
      pool::poolClose(db_pool)
    },
    teardown_env()
  )
}
