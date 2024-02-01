# unbiased
API for clinical trial randomization

## Configuration

The Unbiased API server can be configured using environment variables. The following environment variables need to be set for the server to start:

- `POSTGRES_DB`: The name of the PostgreSQL database to connect to.
- `POSTGRES_HOST`: The host of the PostgreSQL database. This could be a hostname, such as `localhost` or `database.example.com`, or an IP address.
- `POSTGRES_PORT`: The port on which the PostgreSQL database is listening. Defaults to `5432` if not provided.
- `POSTGRES_USER`: The username for authentication with the PostgreSQL database.
- `POSTGRES_PASSWORD`: The password for authentication with the PostgreSQL database.
- `UNBIASED_HOST`: The host on which the API will run. Defaults to `0.0.0.0` if not provided.
- `UNBIASED_PORT`: The port on which the API will listen. Defaults to `3838` if not provided.

## Running Tests

Unbiased provides an extensive collection of tests to ensure correct functionality.

### Executing Tests from an R Interactive Session

To execute tests using an interactive R session, run the following commands:

```R
devtools::load_all()
testthat::test_package("unbiased")
```

Ensure that the necessary database connection environment variables are set before running these tests. You can set environment variables using methods such as `Sys.setenv`.

Running these tests will start the Unbiased API on a random port.

### Executing Tests from the Command Line

Use the helper script `run_tests.sh` to execute tests from the command line. Remember to set the database connection environment variables before running the tests.

### Running Tests with Docker Compose

Docker Compose can be used to build the Unbiased Docker image and execute all tests. This can be done using the provided `docker-compose.test.yml` file. This method ensures a consistent testing environment and simplifies the setup process.

```bash
docker compose -f docker-compose.test.yml build
docker compose -f docker-compose.test.yml run tests
```

### Executing with Coverage

For test coverage, use the `covr::report()` method. This will run all tests and provide a coverage report in HTML format. For a simpler code coverage report, use the `covr::package_coverage()` method.

You can also use the `run_tests_with_coverage.sh` script to run Unbiased tests with code coverage.
