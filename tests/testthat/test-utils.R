# Tests for utility functions
# Author: jonghyeonseol
# Date: 2025-11-13

context("Utility Functions Tests")

test_that("sanitize_file_path detects directory traversal", {
  # Should detect directory traversal attempts
  expect_error(sanitize_file_path("../../../etc/passwd"),
               "directory traversal")
  expect_error(sanitize_file_path("test/../../../secret"),
               "directory traversal")

  # Should allow normal paths
  expect_silent(sanitize_file_path("Input/test.txt"))
})

test_that("extract_go_info extracts GO term and ID correctly", {
  full_term <- "neutrophil aggregation (GO:0070488)"
  result <- extract_go_info(full_term)

  expect_equal(result$go_term, "neutrophil aggregation")
  expect_equal(result$go_id, "GO:0070488")
})

test_that("format_pvalue formats correctly", {
  # Small p-value
  expect_match(format_pvalue(0.0001), "1.00e-04")

  # Larger p-value
  expect_match(format_pvalue(0.0234), "0.0234")

  # NA value
  expect_equal(format_pvalue(NA), "NA")
})

test_that("check_dependencies works", {
  # This should return TRUE since we've loaded the packages
  expect_true(check_dependencies())
})

test_that("validate_input_file detects invalid files", {
  # Non-existent file
  expect_false(validate_input_file("non_existent_file.txt"))

  # Test with actual input file (if available)
  input_files <- list.files("Input", pattern = "\\.txt$", full.names = TRUE)
  if (length(input_files) > 0) {
    expect_true(validate_input_file(input_files[1]))
  }
})

test_that("get_output_path constructs correct paths", {
  barplot_path <- get_output_path("Dataset1_GOBP_Up.txt", "barplot")
  expect_match(barplot_path, "Dataset1_GOBP_Up_barplot")
  expect_match(barplot_path, "Barplots")

  dotplot_path <- get_output_path("Dataset1_GOBP_Up.txt", "dotplot")
  expect_match(dotplot_path, "Dataset1_GOBP_Up_dotplot")
  expect_match(dotplot_path, "Dotplots")
})

test_that("log functions work without errors", {
  # These should not throw errors
  expect_silent(log_info("Test info message"))
  expect_silent(log_warn("Test warning message"))
  expect_silent(log_error("Test error message"))
})
