# **unbiased**: An R package for Clinical Trial Randomization

The challenge of allocating participants fairly and efficiently is a cornerstone for the success of clinical trials. Recognizing this critical need, we developed the **unbiased** package. This tool is designed to offer a comprehensive suite of randomization algorithms, suitable for a wide range of clinical trial designs.

## Why choose **unbiased**?

Our goal in creating **unbiased** was to provide a user-friendly yet powerful tool that addresses the nuanced demands of clinical trial randomization. It offers:

- **Ease of Integration**: Designed to fit effortlessly into your research workflow.
- **Adaptability**: Whether for small-scale studies or large, multi-center trials, **unbiased** scales to meet your needs.
- **Comprehensive Documentation**: To support you in applying the package effectively.

By choosing **unbiased**, you're adopting a sophisticated approach to trial randomization, ensuring fair and efficient participant allocation across your studies.

## Core features

The **unbiased** package integrates dynamic and traditional randomization methods, including:

- **Minimization Method**: For balanced allocation considering covariates.
- **Simple Randomization**: For straightforward, unbiased participant assignment.
- **Block Randomization**: To ensure equal group sizes throughout the trial.

Available both as a standard R package and through an API, **unbiased** provides flexibility for researchers. It ensures seamless integration with electronic Case Report Form (eCRF) systems, facilitating efficient patient management.

## Table of Contents
1. [Background](#background)
   - [Purpose and Scope for Clinical Trial Randomization](#purpose-and-scope-for-clinical-trial-randomization)
   - [Comparative Analysis of Randomization Methods](#comparative-analysis-of-randomization-methods)
   - [Comparison with other solutions](#comparison-with-other-solutions)
2. [Installation](#installation)
   - [Installation Instructions](#installation-instructions)
   - [Deploying the API](#deploying-the-api)
4. [Getting Started](#getting-started)
   - [Quickstart Guide](#quickstart-guide)
   - [Basic Usage Examples](#basic-usage-examples)
3. [Technical Implementation](#technical-implementation)
   - [Quality Assurance Measures](#quality-assurance-measures)

# Background

## Purpose and Scope for Clinical Trial Randomization

Randomization is a fundamental aspect of clinical trials, ensuring that participants are allocated to treatment groups in an unbiased manner. This is essential for maintaining the integrity of the trial and ensuring that the results are reliable. The primary goal of randomization is to minimize the potential for bias and confounding factors that could affect the outcome of the trial.

The **unbiased** package provides a comprehensive suite of randomization algorithms to support a wide range of clinical trial designs. It is designed to be flexible and adaptable, allowing researchers to select the most appropriate randomization method for their specific study.

## Comparative Analysis of Randomization Methods

(Ola - skrócona wersja z winietki, może obrazki?)

The **unbiased** package offers a range of randomization methods, each with its own strengths and limitations. The choice of randomization method will depend on the specific requirements of the trial, including the number of treatment groups, the size of the trial, and the need for stratification or minimization.

The **unbiased** package includes the following randomization methods:

- **Simple Randomization**: This is the most basic form of randomization, in which participants are assigned to treatment groups with equal probability. This method is simple and easy to implement, but it does not account for any potential imbalances in baseline characteristics between treatment groups.

- **Block Randomization**: This method involves dividing participants into blocks and then randomly assigning them to treatment groups within each block. This ensures that the number of participants in each treatment group is balanced over time, but it does not account for any potential imbalances in baseline characteristics between treatment groups.

- **Minimization Method**: This method is designed to minimize imbalances in baseline characteristics between treatment groups. It uses an adaptive algorithm to assign participants to treatment groups based on their baseline characteristics, with the goal of achieving balance across treatment groups.

...

To find out more, read our vignette on [Comparative Analysis of Randomization Methods](vignettes/minimization_randomization_comparison.Rmd).

## Comparison with other solutions

(Ola - randpack, others...?)


# Getting Started

Initiating your work with **unbiased** involves simple setup steps. Whether you're integrating it into your R environment or deploying its API, we provide detailed instructions and examples to facilitate a smooth start. We aim to equip you with a reliable tool that enhances the integrity and efficiency of your clinical trials.

## Installation

The **unbiased** package can be installed from GitHub using the `devtools` package. To install **unbiased**, run the following command in your R environment:

```R
devtools::install_github("ttscience/unbiased")
```

## Deploying the API

Execute the API by calling the`run_unbiased()` function:
```R
unbiased::run_unbiased()
```
After running this command, the API should be up and running, as default listening on a port on your localhost (http://localhost:3838). You can interact with the API using any HTTP client, such as curl in the command line, Postman, or directly from R using packages like httr.

## API configuration

The **unbiased** API server can be configured using environment variables. The following environment variables need to be set for the server to start:

- `POSTGRES_DB`: The name of the PostgreSQL database to connect to.
- `POSTGRES_HOST`: The host of the PostgreSQL database. This could be a hostname, such as `localhost` or `database.example.com`, or an IP address.
- `POSTGRES_PORT`: The port on which the PostgreSQL database is listening. Defaults to `5432` if not provided.
- `POSTGRES_USER`: The username for authentication with the PostgreSQL database.
- `POSTGRES_PASSWORD`: The password for authentication with the PostgreSQL database.
- `UNBIASED_HOST`: The host on which the API will run. Defaults to `0.0.0.0` if not provided.
- `UNBIASED_PORT`: The port on which the API will listen. Defaults to `3838` if not provided.

# Use Cases

## Using randomization functions within R

The **unbiased** package provides a set of functions that can be used to perform randomization within R. These functions can be used to assign participants to treatment groups in a clinical trial, ensuring that the randomization process is unbiased and transparent.


### Simple randomization

```R
# Load the unbiased package
library(unbiased)

# Create a data frame with participant IDs and treatment group assignments
participants <- data.frame(
  id = 1:100,
  treatment_group = simple_randomization(100, 2)
)

```

### Minimization method

The minimization method function provided by **unbiased** assume that there is a study initialized and the previous patients assigments is stored in the dataframe/database. The functions will then use this data to assign new participant to treatment groups in a way that minimizes the potential for bias and confounding factors. If the data is not available (e.g. when first patient is randomized), he will be randomly assigned to a treatment group.

```R
# Load the unbiased package
library(unbiased)

# Create a data frame with participant IDs and treatment group assignments
participants <- data.frame(
  id = 1:100,
  treatment_group = minimization_method(
    100,
    2,
    covariates = c("age
  ))
```

## API endpoints

### Study creation

### Patient randomization

# Technical details

## Running Tests

Unbiased provides an extensive collection of tests to ensure correct functionality.

### Executing Tests from an R Interactive Session

To execute tests using an interactive R session, run the following commands:

```R
devtools::load_all()
testthat::test_package(**unbiased**)
```

Make sure that `devtools` package is installed in your environment.

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

### Code Coverage

Unbiased supports code coverage analysis through the `covr` package. This allows you to measure the effectiveness of your tests by showing which parts of your R code in the `R` directory are actually being tested.

To calculate code coverage, you will need to install the `covr` package. Once installed, you can use the following methods:

- `covr::report()`: This method runs all tests and generates a detailed coverage report in HTML format.
- `covr::package_coverage()`: This method provides a simpler, text-based code coverage report.

Alternatively, you can use the provided `run_tests_with_coverage.sh` script to run Unbiased tests with code coverage.
