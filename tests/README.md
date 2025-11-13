# Tests for Gene Ontology Analysis Visualization

This directory contains unit tests for the Gene Ontology Analysis project.

## Running Tests

### Prerequisites

Install the testthat package:
```r
install.packages("testthat")
```

### Run All Tests

From the project root directory:
```r
# Load testthat
library(testthat)

# Run all tests
test_dir("tests/testthat")
```

Or run individual test files:
```r
# Test configuration
test_file("tests/testthat/test-config.R")

# Test utilities
test_file("tests/testthat/test-utils.R")

# Test data reading
test_file("tests/testthat/test-read_go_results.R")

# Test visualization
test_file("tests/testthat/test-visualization.R")
```

## Test Structure

- `test-config.R` - Tests for configuration management functions
- `test-utils.R` - Tests for utility functions (validation, logging, etc.)
- `test-read_go_results.R` - Tests for data reading and processing
- `test-visualization.R` - Tests for plot generation functions

## Test Coverage

The tests cover:
- Configuration management
- Input validation
- File processing
- Data filtering and transformation
- Visualization generation
- Error handling

## Adding New Tests

When adding new functionality, create corresponding tests:

1. Create a new test file in `tests/testthat/` with prefix `test-`
2. Use `context()` to describe the test group
3. Use `test_that()` for individual tests
4. Follow the existing test patterns

Example:
```r
context("My New Feature Tests")

test_that("feature works correctly", {
  result <- my_function(input)
  expect_equal(result, expected_output)
})
```
