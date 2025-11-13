# Tests for read_go_results function
# Author: jonghyeonseol
# Date: 2025-11-13

context("GO Results Reading Tests")

test_that("read_go_results handles empty files", {
  # Create a temporary empty file
  temp_file <- tempfile(fileext = ".txt")
  writeLines(character(0), temp_file)

  expect_null(read_go_results(temp_file))

  unlink(temp_file)
})

test_that("read_go_results handles files with insufficient lines", {
  # Create a file with too few lines
  temp_file <- tempfile(fileext = ".txt")
  writeLines(c("line1", "line2", "line3"), temp_file)

  expect_null(read_go_results(temp_file))

  unlink(temp_file)
})

test_that("read_go_results processes valid files correctly", {
  # Test with actual input files if available
  input_files <- list.files("Input", pattern = "\\.txt$", full.names = TRUE)

  if (length(input_files) > 0) {
    # Test first file
    result <- read_go_results(input_files[1])

    if (!is.null(result)) {
      # Check that result is a data frame
      expect_s3_class(result, "data.frame")

      # Check that required columns exist
      required_cols <- c("GO_Term", "GO_ID", "Count", "P.value",
                         "FDR", "Gene_Ratio", "neg_log10_pvalue")
      for (col in required_cols) {
        expect_true(col %in% colnames(result),
                    info = sprintf("Column '%s' should exist", col))
      }

      # Check that fold enrichment filter was applied
      if ("Fold_Enrichment" %in% colnames(result)) {
        expect_true(all(result$Fold_Enrichment >= get_config("fold_enrichment_threshold", 10)))
      }

      # Check that we have at most top_n_terms rows
      expect_true(nrow(result) <= get_config("top_n_terms", 20))
    }
  } else {
    skip("No input files available for testing")
  }
})

test_that("read_go_results handles non-existent files", {
  expect_null(read_go_results("non_existent_file.txt"))
})
