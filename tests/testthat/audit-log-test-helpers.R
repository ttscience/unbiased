#' Assert Events Logged in Audit Trail
#'
#' This function checks if the expected events have been logged in the 'audit_log' table in the database.
#' This function should be used at the beginning of a test to ensure that the expected events are logged.
#' @param events A vector of expected event types that should be logged, in order
#'
#' @return This function does not return a value. It throws an error if the assertions fail.
#'
#' @examples
#' \dontrun{
#' assert_events_logged(c("event1", "event2"))
#' }
assert_audit_trail_for_test <- function(events = list(), env = parent.frame()) {
  # Get count of events logged from audit_log table in database
  pool <- get("db_connection_pool", envir = .GlobalEnv)
  conn <- pool::localCheckout(pool)

  event_count <- DBI::dbGetQuery(
    conn,
    "SELECT COUNT(*) FROM audit_log"
  )$count

  withr::defer(
    {
      # gen new count
      new_event_count <- DBI::dbGetQuery(
        conn,
        "SELECT COUNT(*) FROM audit_log"
      )$count

      n <- length(events)

      # assert that the count has increased by number of events
      testthat::expect_identical(
        new_event_count,
        event_count + n,
        info = glue::glue("Expected {n} events to be logged")
      )

      if (n > 0) {
        # get the last n events
        last_n_events <- DBI::dbGetQuery(
          conn,
          glue::glue_sql(
            "SELECT * FROM audit_log ORDER BY created_at DESC LIMIT {n};",
            .con = conn
          )
        )

        event_types <- last_n_events |>
          dplyr::pull("event_type") |>
          rev()

        # assert that the last n events are the expected events
        testthat::expect_equal(
          event_types,
          events,
          info = "Expected events to be logged"
        )
      }
    },
    env
  )
}
