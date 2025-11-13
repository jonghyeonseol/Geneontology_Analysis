# Tests for heatmap visualization
# Author: jonghyeonseol
# Date: 2025-11-13

context("Heatmap Visualization Tests")

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

test_that("create_heatmap returns ggplot object for valid data list", {
  sample_data1 <- create_sample_data()
  sample_data2 <- create_sample_data()
  sample_data2$Count <- sample_data2$Count + 2

  data_list <- list("Dataset1" = sample_data1, "Dataset2" = sample_data2)

  plot <- create_heatmap(data_list, value_type = "pvalue")

  expect_s3_class(plot, "ggplot")
})

test_that("create_heatmap handles NULL data list", {
  plot <- create_heatmap(NULL)
  expect_null(plot)
})

test_that("create_heatmap handles empty data list", {
  empty_list <- list()
  plot <- create_heatmap(empty_list)
  expect_null(plot)
})

test_that("create_heatmap handles single dataset", {
  sample_data <- create_sample_data()
  data_list <- list("Dataset1" = sample_data)

  # Should work but may not cluster
  plot <- create_heatmap(data_list)
  # With single dataset, still returns a plot
  expect_true(is.null(plot) || inherits(plot, "ggplot"))
})

test_that("create_heatmap handles different value types", {
  sample_data1 <- create_sample_data()
  sample_data2 <- create_sample_data()
  data_list <- list("D1" = sample_data1, "D2" = sample_data2)

  # P-value
  plot1 <- create_heatmap(data_list, value_type = "pvalue")
  expect_s3_class(plot1, "ggplot")

  # Fold enrichment
  plot2 <- create_heatmap(data_list, value_type = "fold_enrichment")
  expect_s3_class(plot2, "ggplot")

  # Count
  plot3 <- create_heatmap(data_list, value_type = "count")
  expect_s3_class(plot3, "ggplot")
})

test_that("create_heatmap respects clustering options", {
  sample_data1 <- create_sample_data()
  sample_data2 <- create_sample_data()
  sample_data2$Count <- sample_data2$Count * 2
  data_list <- list("D1" = sample_data1, "D2" = sample_data2)

  # With clustering
  plot1 <- create_heatmap(data_list, cluster_rows = TRUE, cluster_cols = TRUE)
  expect_s3_class(plot1, "ggplot")

  # Without clustering
  plot2 <- create_heatmap(data_list, cluster_rows = FALSE, cluster_cols = FALSE)
  expect_s3_class(plot2, "ggplot")
})
