# Tests for visualization functions
# Author: jonghyeonseol
# Date: 2025-11-13

context("Visualization Tests")

# Create sample data for testing
create_sample_data <- function() {
  data.frame(
    GO_Term = c("Term1", "Term2", "Term3"),
    GO_ID = c("GO:0001", "GO:0002", "GO:0003"),
    Count = c(10, 8, 6),
    P.value = c(0.001, 0.01, 0.05),
    FDR = c(0.01, 0.05, 0.1),
    Gene_Ratio = c(0.1, 0.08, 0.06),
    neg_log10_pvalue = -log10(c(0.001, 0.01, 0.05)),
    Fold_Enrichment = c(20, 15, 12),
    stringsAsFactors = FALSE
  )
}

test_that("create_barplot returns ggplot object for valid data", {
  sample_data <- create_sample_data()
  plot <- create_barplot(sample_data, "Test Barplot")

  expect_s3_class(plot, "ggplot")
})

test_that("create_barplot handles NULL data", {
  plot <- create_barplot(NULL, "Test Barplot")
  expect_null(plot)
})

test_that("create_barplot handles empty data frame", {
  empty_data <- data.frame()
  plot <- create_barplot(empty_data, "Test Barplot")
  expect_null(plot)
})

test_that("create_dotplot returns ggplot object for valid data", {
  sample_data <- create_sample_data()
  plot <- create_dotplot(sample_data, "Test Dotplot")

  expect_s3_class(plot, "ggplot")
})

test_that("create_dotplot handles NULL data", {
  plot <- create_dotplot(NULL, "Test Dotplot")
  expect_null(plot)
})

test_that("create_dotplot handles empty data frame", {
  empty_data <- data.frame()
  plot <- create_dotplot(empty_data, "Test Dotplot")
  expect_null(plot)
})

test_that("plots can be saved without errors", {
  sample_data <- create_sample_data()
  barplot <- create_barplot(sample_data, "Test Barplot")
  dotplot <- create_dotplot(sample_data, "Test Dotplot")

  # Create temporary files
  temp_barplot <- tempfile(fileext = ".png")
  temp_dotplot <- tempfile(fileext = ".png")

  # Save plots
  expect_silent(ggsave(temp_barplot, barplot, width = 12, height = 8, dpi = 300))
  expect_silent(ggsave(temp_dotplot, dotplot, width = 12, height = 8, dpi = 300))

  # Check that files were created
  expect_true(file.exists(temp_barplot))
  expect_true(file.exists(temp_dotplot))

  # Clean up
  unlink(temp_barplot)
  unlink(temp_dotplot)
})
