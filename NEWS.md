# unbiased 1.0.2

## Bug Fixes

- Fixed incorrect ratio allocation in minimisation randomization when unequal allocation ratios were provided. This was caused by a logic bug; updating a single line in `randomize-minimisation-pocock.R` restores expected allocation behavior.

# unbiased 1.0.1

## Bug Fixes

- Fixed and issue when too aggressive input validation in the `randomize` endpoint was causing the API to reject valid requests with `current_state` of length other than 2.

## DevOps

- Updated docker build GitHub Action to use the latest version of cosign and checkout actions.

# unbiased 1.0.0

## New Features

- **Adaptive Randomization Support:**
  - Implemented support for adaptive randomization using Pocock’s minimization algorithm, integrating a new R function based on the Minirand package by Man Jin, Adam Polis, and Jonathan Hartzel ([Minirand Package](https://CRAN.R-project.org/package=Minirand)).
  - Introduced new POST endpoints facilitating the creation of studies and randomization of subjects.

- **Enhanced Retrieval Capabilities:**
  - Added new GET endpoints for comprehensive access to study overviews, in-depth details, and information on randomized patients.

- **Audit Trial Mechanism:**
  - Implemented an audit trial mechanism that systematically logs and stores each request in the database alongside `unbiased`’s response.
  - Introduced a new GET endpoint enabling users to access the complete audit trail for a specific study.

## Vignettes / Articles

- Added a new article benchmarking Pocock’s minimization algorithm against permuted block randomization and simple randomization, focusing on the balance of covariates.

## DevOps Integration

- Integrated project with Sentry to capture errors, empowering users to provide their credentials and receive notifications in the event of unexpected occurrences, including HTTP 500 instances.
- Implemented GitHub Actions CI, ensuring that all tests must pass before merging.
  - Integrated project with CodeCov, achieving a code coverage of 95% or higher, with maintenance of the same level or improvement required for merging.
  - Integrated project with pkgdown, hosting the project site at [ttscience.github.io/unbiased/](https://ttscience.github.io/unbiased/).
  - Enforced the use of a linter, ensuring no errors are present upon merging.

## Smaller Improvements

- Improved handling of malformed JSONs, now returning HTTP 400 instead of the default HTTP 500 (plumber behavior).
