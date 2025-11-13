# GO Analysis Visualization using ClusterProfiler-style plots
# Author: Generated for Geneontology_Analysis
# Date: 2025-11-07
# Updated: 2025-11-13

# Load configuration and utilities
source("config.R")
source("utils.R")

# Load required libraries
library(ggplot2)
library(dplyr)
library(stringr)

#' Read and Process GO Enrichment Results
#'
#' @description Reads PANTHER GO enrichment files and processes them for visualization
#' @param file_path Path to the PANTHER enrichment file
#' @return Data frame with processed GO enrichment results or NULL if processing fails
#' @export
#'
#' @details
#' The function performs the following operations:
#' \itemize{
#'   \item Validates input file format
#'   \item Extracts total analyzed gene count from header
#'   \item Parses tab-separated GO enrichment data
#'   \item Filters by fold enrichment threshold
#'   \item Calculates gene ratio and -log10(p-value)
#'   \item Selects top N terms by p-value
#' }
#'
#' @examples
#' \dontrun{
#' data <- read_go_results("Input/Dataset1_GOBP_Up.txt")
#' }
read_go_results <- function(file_path) {
  # Validate input file
  if (!validate_input_file(file_path)) {
    return(NULL)
  }

  # Read all lines
  lines <- readLines(file_path, warn = FALSE)

  # Get configuration values
  header_line <- get_config("header_line_number", 12)
  data_start_line <- get_config("data_start_line", 13)
  min_lines <- get_config("min_file_lines", 12)

  # Check if file has enough lines
  if (length(lines) <= min_lines) {
    log_warn(sprintf("File has insufficient data: %s", basename(file_path)))
    return(NULL)
  }

  # Extract total analyzed genes from header (line 12)
  header_line_text <- lines[header_line]
  # Pattern: upload_1 (29) - extract the number inside parentheses
  total_genes_match <- str_extract(header_line_text, "upload_1 \\((\\d+)\\)")
  # Extract only the number inside parentheses (not the "1" from "upload_1")
  total_genes <- as.numeric(str_extract(total_genes_match, "(?<=\\()\\d+(?=\\))"))

  if (is.na(total_genes) || total_genes <= 0) {
    log_error(sprintf("Cannot extract valid gene count from: %s", basename(file_path)))
    return(NULL)
  }

  log_info(sprintf("Total genes analyzed: %d", total_genes))

  # Get data lines (starting from line 13)
  data_lines <- lines[data_start_line:length(lines)]

  # Remove empty lines
  data_lines <- data_lines[data_lines != ""]

  if (length(data_lines) == 0) {
    log_warn(sprintf("No data lines found in: %s", basename(file_path)))
    return(NULL)
  }

  # Parse data manually
  data_list <- lapply(data_lines, function(line) {
    strsplit(line, "\t")[[1]]
  })

  # Convert to data frame
  data <- as.data.frame(do.call(rbind, data_list), stringsAsFactors = FALSE)

  # Set column names
  colnames(data) <- c("Full_Term", "REFLIST", "Count", "Expected", "Direction",
                      "Fold_Enrichment", "P.value", "FDR")

  # Extract GO term name and ID from the first column
  data$GO_Term <- gsub("\\s*\\(GO:\\d+\\)", "", data$Full_Term)
  data$GO_ID <- str_extract(data$Full_Term, "GO:\\d+")

  # Convert numeric columns
  data$Count <- as.numeric(data$Count)

  # Handle fold enrichment with "> 100" values
  fold_ceiling <- get_config("fold_enrichment_ceiling", 100)
  data$Fold_Enrichment <- gsub("\\s*>\\s*", "", data$Fold_Enrichment)
  data$Fold_Enrichment <- suppressWarnings(as.numeric(data$Fold_Enrichment))
  data$Fold_Enrichment[is.na(data$Fold_Enrichment)] <- fold_ceiling

  # Convert p-values
  data$P.value <- as.numeric(data$P.value)
  data$FDR <- as.numeric(data$FDR)

  # Remove rows with NA in critical columns
  data <- data[!is.na(data$Count) & !is.na(data$FDR), ]

  if (nrow(data) == 0) {
    log_warn(sprintf("No valid data rows in: %s", basename(file_path)))
    return(NULL)
  }

  # Filter by Fold Enrichment threshold
  fold_threshold <- get_config("fold_enrichment_threshold", 10)
  data <- data[data$Fold_Enrichment >= fold_threshold, ]

  if (nrow(data) == 0) {
    log_warn(sprintf("No terms meet fold enrichment threshold (>= %d): %s",
                     fold_threshold, basename(file_path)))
    return(NULL)
  }

  # Calculate Gene Ratio
  data$Gene_Ratio <- data$Count / total_genes

  # Calculate -log10(p-value) for visualization
  data$neg_log10_pvalue <- -log10(data$P.value)

  # Select top terms (by p-value significance)
  top_n <- get_config("top_n_terms", 20)
  data <- data %>%
    arrange(P.value) %>%
    head(top_n)

  log_info(sprintf("Processed %d significant GO terms", nrow(data)))

  return(data)
}

#' Create Barplot for GO Enrichment
#'
#' @description Creates a horizontal bar plot showing gene count per GO term
#' @param data Data frame with processed GO enrichment results
#' @param title Plot title
#' @return ggplot2 object or NULL if data is invalid
#' @export
#'
#' @details
#' The barplot displays:
#' \itemize{
#'   \item X-axis: Gene count
#'   \item Y-axis: GO terms
#'   \item Color: -log10(p-value) gradient
#' }
create_barplot <- function(data, title) {
  if (is.null(data) || nrow(data) == 0) {
    log_warn("No data available for barplot")
    return(NULL)
  }

  # Get configuration
  color_low <- get_config("color_low", "blue")
  color_high <- get_config("color_high", "red")
  font_size_axis_text <- get_config("font_size_axis_text", 10)
  font_size_axis_title <- get_config("font_size_axis_title", 12)
  font_size_plot_title <- get_config("font_size_plot_title", 14)

  # Prepare data for plotting
  # When Count is the same, sort by p-value in descending order
  sort_by <- get_config("barplot_sort_by", "count")
  secondary_sort <- get_config("secondary_sort_by", "pvalue")
  secondary_order <- get_config("secondary_sort_order", "desc")

  if (secondary_order == "desc") {
    plot_data <- data %>%
      arrange(!!sym(ifelse(sort_by == "count", "Count", "P.value")),
              desc(P.value)) %>%
      mutate(GO_Term = factor(GO_Term, levels = GO_Term))
  } else {
    plot_data <- data %>%
      arrange(!!sym(ifelse(sort_by == "count", "Count", "P.value")),
              P.value) %>%
      mutate(GO_Term = factor(GO_Term, levels = GO_Term))
  }

  p <- ggplot(plot_data, aes(x = Count, y = GO_Term, fill = neg_log10_pvalue)) +
    geom_bar(stat = "identity") +
    scale_fill_gradient(low = color_low, high = color_high, name = "-log10(p-value)") +
    labs(title = title,
         x = "Gene Count",
         y = "GO Term") +
    theme_minimal() +
    theme(axis.text.y = element_text(size = font_size_axis_text),
          axis.text.x = element_text(size = font_size_axis_text),
          axis.title = element_text(size = font_size_axis_title, face = "bold"),
          plot.title = element_text(size = font_size_plot_title, face = "bold", hjust = 0.5),
          legend.position = "right")

  return(p)
}

#' Create Dotplot for GO Enrichment
#'
#' @description Creates a dot plot showing gene ratio vs GO terms
#' @param data Data frame with processed GO enrichment results
#' @param title Plot title
#' @return ggplot2 object or NULL if data is invalid
#' @export
#'
#' @details
#' The dotplot displays:
#' \itemize{
#'   \item X-axis: Gene ratio (proportion of genes)
#'   \item Y-axis: GO terms
#'   \item Point size: Gene count
#'   \item Point color: -log10(p-value) gradient
#' }
create_dotplot <- function(data, title) {
  if (is.null(data) || nrow(data) == 0) {
    log_warn("No data available for dotplot")
    return(NULL)
  }

  # Get configuration
  color_low <- get_config("color_low", "blue")
  color_high <- get_config("color_high", "red")
  point_size_min <- get_config("point_size_min", 3)
  point_size_max <- get_config("point_size_max", 10)
  font_size_dotplot_y <- get_config("font_size_dotplot_y", 15)
  font_size_axis_text <- get_config("font_size_axis_text", 10)
  font_size_axis_title <- get_config("font_size_axis_title", 12)
  font_size_plot_title <- get_config("font_size_plot_title", 14)

  # Prepare data for plotting (highest Gene Ratio at top - descending order)
  # When Gene_Ratio is the same, sort by p-value in descending order
  sort_by <- get_config("dotplot_sort_by", "gene_ratio")
  secondary_sort <- get_config("secondary_sort_by", "pvalue")
  secondary_order <- get_config("secondary_sort_order", "desc")

  if (secondary_order == "desc") {
    plot_data <- data %>%
      arrange(!!sym(ifelse(sort_by == "gene_ratio", "Gene_Ratio", "P.value")),
              desc(P.value)) %>%
      mutate(GO_Term = factor(GO_Term, levels = GO_Term))
  } else {
    plot_data <- data %>%
      arrange(!!sym(ifelse(sort_by == "gene_ratio", "Gene_Ratio", "P.value")),
              P.value) %>%
      mutate(GO_Term = factor(GO_Term, levels = GO_Term))
  }

  p <- ggplot(plot_data, aes(x = Gene_Ratio, y = GO_Term)) +
    geom_point(aes(size = Count, color = neg_log10_pvalue)) +
    scale_color_gradient(low = color_low, high = color_high, name = "-log10(p-value)") +
    scale_size_continuous(name = "Gene Count", range = c(point_size_min, point_size_max)) +
    labs(title = title,
         x = "Gene Ratio",
         y = "GO Term") +
    theme_minimal() +
    theme(axis.text.y = element_text(size = font_size_dotplot_y),
          axis.text.x = element_text(size = font_size_axis_text),
          axis.title = element_text(size = font_size_axis_title, face = "bold"),
          plot.title = element_text(size = font_size_plot_title, face = "bold", hjust = 0.5),
          legend.position = "right")

  return(p)
}

#' Main Processing Pipeline
#'
#' @description Main function to process all GO enrichment files and generate visualizations
#' @export
main <- function() {
  # Print session info
  print_session_info()

  # Check dependencies
  if (!check_dependencies()) {
    stop("Missing required packages. Please install them before continuing.")
  }

  # Validate configuration
  validate_config()

  # Create output directories
  create_output_directories()

  # Get input files
  input_dir <- get_config("input_dir", "Input")
  input_pattern <- get_config("input_file_pattern", "\\.txt$")
  input_files <- list.files(input_dir, pattern = input_pattern, full.names = TRUE)

  if (length(input_files) == 0) {
    log_error(sprintf("No input files found in %s", input_dir))
    stop("No input files to process")
  }

  log_info(sprintf("Found %d input files to process", length(input_files)))
  log_info("=================================")

  # Process each file
  processed_count <- 0
  skipped_count <- 0

  for (file in input_files) {
    file_name <- basename(file)
    file_base <- tools::file_path_sans_ext(file_name)

    log_info(sprintf("Processing: %s", file_name))

    # Read and process data
    go_data <- read_go_results(file)

    if (is.null(go_data) || nrow(go_data) == 0) {
      log_warn(sprintf("Skipping %s - no significant results found", file_name))
      skipped_count <- skipped_count + 1
      next
    }

    log_info(sprintf("Found %d significant GO terms", nrow(go_data)))

    # Create barplot
    barplot <- create_barplot(go_data, paste("GO Enrichment -", file_base))
    if (!is.null(barplot)) {
      barplot_file <- get_output_path(file_name, "barplot")
      ggsave(barplot_file, barplot,
             width = get_config("plot_width", 12),
             height = get_config("plot_height", 8),
             dpi = get_config("output_dpi", 300))
      log_info(sprintf("Barplot saved: %s", barplot_file))
    }

    # Create dotplot
    dotplot <- create_dotplot(go_data, paste("GO Enrichment -", file_base))
    if (!is.null(dotplot)) {
      dotplot_file <- get_output_path(file_name, "dotplot")
      ggsave(dotplot_file, dotplot,
             width = get_config("plot_width", 12),
             height = get_config("plot_height", 8),
             dpi = get_config("output_dpi", 300))
      log_info(sprintf("Dotplot saved: %s", dotplot_file))
    }

    processed_count <- processed_count + 1
    log_info("")
  }

  # Summary
  log_info("=================================")
  log_info("Processing Summary:")
  log_info(sprintf("  Total files: %d", length(input_files)))
  log_info(sprintf("  Successfully processed: %d", processed_count))
  log_info(sprintf("  Skipped: %d", skipped_count))
  log_info("=================================")
  log_info("All visualizations completed!")
  log_info(sprintf("Results saved in %s and %s",
                   get_config("barplot_dir", "Output/Barplots"),
                   get_config("dotplot_dir", "Output/Dotplots")))
}

# Run main pipeline
if (!interactive()) {
  main()
} else {
  cat("Gene Ontology Visualization Pipeline Loaded\n")
  cat("Run main() to process all files\n")
  cat("Or use read_go_results(), create_barplot(), create_dotplot() individually\n")
}
