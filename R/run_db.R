# db_connection_pool <- NULL

create_db_connection_pool <- purrr::insistently(function() {
  pool::dbPool(
    RPostgres::Postgres(),
    dbname = Sys.getenv("POSTGRES_DB"),
    host = Sys.getenv("POSTGRES_HOST"),
    port = Sys.getenv("POSTGRES_PORT", 5432),
    user = Sys.getenv("POSTGRES_USER"),
    password = Sys.getenv("POSTGRES_PASSWORD")
  )
}, rate = purrr::rate_delay(2, max_times = 5))
