db_pool <- create_db_connection_pool()
conn <- pool::poolCheckout(db_pool)

assign("conn", conn, envir = .GlobalEnv)
assign("db_pool", db_pool, envir = .GlobalEnv)

# Close DB connection upon exiting
withr::defer(
  {
    pool::poolReturn(conn)
    pool::poolClose(db_pool)
  },
  teardown_env()
)
