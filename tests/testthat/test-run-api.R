testthat::test_that("uses correct environment variables when setting up sentry", {
  withr::local_envvar(
    c(
      SENTRY_DSN = "https://sentry.io/123",
      GITHUB_SHA = "abc",
      SENTRY_ENVIRONMENT = "production",
      SENTRY_RELEASE = "1.0.0"
    )
  )

  testthat::local_mocked_bindings(
    configure_sentry = function(dsn,
                                app_name,
                                app_version,
                                environment,
                                release) {
      testthat::expect_equal(dsn, "https://sentry.io/123")
      testthat::expect_equal(app_name, "unbiased")
      testthat::expect_equal(app_version, "abc")
      testthat::expect_equal(environment, "production")
      testthat::expect_equal(release, "1.0.0")
    },
    .package = "sentryR",
  )

  global_calling_handlers_called <- FALSE

  # mock globalCallingHandlers
  testthat::local_mocked_bindings(
    globalCallingHandlers = function(error) {
      global_calling_handlers_called <<- TRUE
      testthat::expect_equal(
        unbiased:::global_calling_handler,
        error
      )
    },
  )

  unbiased:::setup_sentry()

  testthat::expect_true(global_calling_handlers_called)
})

testthat::test_that("skips sentry setup if SENTRY_DSN is not set", {
  withr::local_envvar(
    c(
      SENTRY_DSN = ""
    )
  )

  testthat::local_mocked_bindings(
    configure_sentry = function(dsn,
                                app_name,
                                app_version,
                                environment,
                                release) {
      # should not be called, so we fail the test
      testthat::expect_true(FALSE)
    },
    .package = "sentryR",
  )

  was_called <- FALSE

  # mock globalCallingHandlers
  testthat::local_mocked_bindings(
    globalCallingHandlers = function(error) {
      was_called <<- TRUE
    },
  )

  testthat::expect_message(unbiased:::setup_sentry(), "SENTRY_DSN not set, skipping Sentry setup")
  testthat::expect_false(was_called)
})

testthat::test_that("global_calling_handler captures exception and signals condition", {
  error <- simpleError("test error")

  capture_exception_called <- FALSE

  testthat::local_mocked_bindings(
    capture_exception = function(error) {
      capture_exception_called <<- TRUE
      testthat::expect_equal(error, error)
    },
    .package = "sentryR",
  )

  testthat::expect_error(unbiased:::global_calling_handler(error))
  testthat::expect_true(capture_exception_called)
})
