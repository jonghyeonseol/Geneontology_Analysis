# Tests for configuration functions
# Author: jonghyeonseol
# Date: 2025-11-13

context("Configuration Tests")

test_that("get_config returns correct values", {
  # Test existing config value
  expect_equal(get_config("fold_enrichment_threshold", NULL), 10)
  expect_equal(get_config("top_n_terms", NULL), 20)

  # Test non-existing config value with default
  expect_equal(get_config("non_existing_key", "default_value"), "default_value")
  expect_null(get_config("non_existing_key", NULL))
})

test_that("set_config modifies configuration", {
  # Save original value
  original_value <- get_config("fold_enrichment_threshold")

  # Modify config
  set_config("fold_enrichment_threshold", 15)
  expect_equal(get_config("fold_enrichment_threshold"), 15)

  # Restore original value
  set_config("fold_enrichment_threshold", original_value)
  expect_equal(get_config("fold_enrichment_threshold"), original_value)
})

test_that("CONFIG list contains required keys", {
  required_keys <- c(
    "fold_enrichment_threshold",
    "top_n_terms",
    "header_line_number",
    "data_start_line",
    "min_file_lines",
    "output_format",
    "output_dpi",
    "plot_width",
    "plot_height"
  )

  for (key in required_keys) {
    expect_true(key %in% names(CONFIG),
                info = sprintf("Key '%s' should exist in CONFIG", key))
  }
})

test_that("Configuration values have correct types", {
  expect_true(is.numeric(CONFIG$fold_enrichment_threshold))
  expect_true(is.numeric(CONFIG$top_n_terms))
  expect_true(is.numeric(CONFIG$output_dpi))
  expect_true(is.numeric(CONFIG$plot_width))
  expect_true(is.numeric(CONFIG$plot_height))
  expect_true(is.character(CONFIG$output_format))
})
