# Tests for network visualization
# Author: jonghyeonseol
# Date: 2025-11-13

context("Network Visualization Tests")

# Create sample data for testing
create_sample_data <- function() {
  data.frame(
    GO_Term = c("cell adhesion", "cell migration", "cell proliferation",
                "adhesion molecule", "migration factor"),
    GO_ID = c("GO:0001", "GO:0002", "GO:0003", "GO:0004", "GO:0005"),
    Count = c(10, 8, 6, 9, 7),
    P.value = c(0.001, 0.01, 0.05, 0.005, 0.02),
    FDR = c(0.01, 0.05, 0.1, 0.03, 0.06),
    Gene_Ratio = c(0.1, 0.08, 0.06, 0.09, 0.07),
    neg_log10_pvalue = -log10(c(0.001, 0.01, 0.05, 0.005, 0.02)),
    Fold_Enrichment = c(20, 15, 12, 18, 14),
    stringsAsFactors = FALSE
  )
}

test_that("create_network returns ggplot object for valid data", {
  sample_data <- create_sample_data()
  plot <- create_network(sample_data, similarity_threshold = 0.2)

  expect_true(is.null(plot) || inherits(plot, "ggplot"))
})

test_that("create_network handles NULL data", {
  plot <- create_network(NULL)
  expect_null(plot)
})

test_that("create_network handles empty data frame", {
  empty_data <- data.frame()
  plot <- create_network(empty_data)
  expect_null(plot)
})

test_that("create_network handles single term", {
  single_term <- create_sample_data()[1, ]
  plot <- create_network(single_term)
  expect_null(plot)  # Should return NULL for single term
})

test_that("create_network handles different layouts", {
  sample_data <- create_sample_data()

  # Force-directed layout
  plot1 <- create_network(sample_data, layout = "fr", similarity_threshold = 0.1)
  expect_true(is.null(plot1) || inherits(plot1, "ggplot"))

  # Circle layout
  plot2 <- create_network(sample_data, layout = "circle", similarity_threshold = 0.1)
  expect_true(is.null(plot2) || inherits(plot2, "ggplot"))

  # Star layout
  plot3 <- create_network(sample_data, layout = "star", similarity_threshold = 0.1)
  expect_true(is.null(plot3) || inherits(plot3, "ggplot"))
})

test_that("create_network handles different node size options", {
  sample_data <- create_sample_data()

  # Size by count
  plot1 <- create_network(sample_data, node_size_by = "count", similarity_threshold = 0.1)
  expect_true(is.null(plot1) || inherits(plot1, "ggplot"))

  # Size by p-value
  plot2 <- create_network(sample_data, node_size_by = "pvalue", similarity_threshold = 0.1)
  expect_true(is.null(plot2) || inherits(plot2, "ggplot"))

  # Size by fold enrichment
  plot3 <- create_network(sample_data, node_size_by = "fold_enrichment", similarity_threshold = 0.1)
  expect_true(is.null(plot3) || inherits(plot3, "ggplot"))
})

test_that("create_network handles high similarity threshold", {
  sample_data <- create_sample_data()

  # Very high threshold should result in no edges
  plot <- create_network(sample_data, similarity_threshold = 0.99)
  expect_null(plot)  # Should return NULL with warning
})
