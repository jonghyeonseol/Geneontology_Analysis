#' Read and Process GO Enrichment Results
#'
#' @description Reads PANTHER GO enrichment files and processes them for visualization
#' @param file_path Path to the PANTHER enrichment file
#' @param strict Logical, if TRUE throws errors instead of returning NULL (default: FALSE)
#' @return Data frame with processed GO enrichment results or NULL if processing fails.
#'   When NULL is returned, a warning is issued with the reason for failure.
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
#' head(data)
#' }
#'
#' @importFrom stringr str_extract
#' @importFrom dplyr arrange mutate
read_go_results <- function(file_path, strict = FALSE) {
  # Validate input file
  validation_result <- validate_input_file(file_path)
  if (!validation_result) {
    msg <- sprintf("Invalid input file: %s - File does not exist, is empty, or has incorrect format", file_path)
    if (strict) {
      stop(msg)
    } else {
      warning(msg, call. = FALSE)
      return(NULL)
    }
  }

  # Read all lines
  lines <- readLines(file_path, warn = FALSE)

  # Get configuration values
  header_line <- get_config("header_line_number", 12)
  data_start_line <- get_config("data_start_line", 13)
  min_lines <- get_config("min_file_lines", 12)

  # Check if file has enough lines
  if (length(lines) <= min_lines) {
    msg <- sprintf("File has insufficient data (only %d lines, need > %d): %s",
                   length(lines), min_lines, basename(file_path))
    log_warn(msg)
    if (strict) {
      stop(msg, call. = FALSE)
    } else {
      warning(msg, call. = FALSE)
      return(NULL)
    }
  }

  # Extract total analyzed genes from header (line 12)
  header_line_text <- lines[header_line]
  # Pattern: upload_1 (29) - extract the number inside parentheses
  total_genes_match <- stringr::str_extract(header_line_text, "upload_1 \\((\\d+)\\)")
  # Extract only the number inside parentheses (not the "1" from "upload_1")
  total_genes <- as.numeric(stringr::str_extract(total_genes_match, "(?<=\\()\\d+(?=\\))"))

  if (is.na(total_genes) || total_genes <= 0) {
    msg <- sprintf("Cannot extract valid gene count from header line %d in file: %s\nExpected format: 'upload_1 (N)' where N is a positive integer",
                   header_line, basename(file_path))
    log_error(msg)
    if (strict) {
      stop(msg, call. = FALSE)
    } else {
      warning(msg, call. = FALSE)
      return(NULL)
    }
  }

  log_info(sprintf("Total genes analyzed: %d", total_genes))

  # Get data lines (starting from line 13)
  data_lines <- lines[data_start_line:length(lines)]

  # Remove empty lines
  data_lines <- data_lines[data_lines != ""]

  if (length(data_lines) == 0) {
    msg <- sprintf("No data lines found after line %d in file: %s",
                   data_start_line, basename(file_path))
    log_warn(msg)
    if (strict) {
      stop(msg, call. = FALSE)
    } else {
      warning(msg, call. = FALSE)
      return(NULL)
    }
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
  data$GO_ID <- stringr::str_extract(data$Full_Term, "GO:\\d+")

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
    msg <- sprintf("No valid data rows after parsing (all rows had NA in Count or FDR): %s",
                   basename(file_path))
    log_warn(msg)
    if (strict) {
      stop(msg, call. = FALSE)
    } else {
      warning(msg, call. = FALSE)
      return(NULL)
    }
  }

  # Filter by Fold Enrichment threshold
  fold_threshold <- get_config("fold_enrichment_threshold", 10)
  data <- data[data$Fold_Enrichment >= fold_threshold, ]

  if (nrow(data) == 0) {
    msg <- sprintf("No GO terms meet fold enrichment threshold (>= %d) in file: %s\nTry lowering the threshold with: set_config('fold_enrichment_threshold', 5)",
                   fold_threshold, basename(file_path))
    log_warn(msg)
    if (strict) {
      stop(msg, call. = FALSE)
    } else {
      warning(msg, call. = FALSE)
      return(NULL)
    }
  }

  # Calculate Gene Ratio
  data$Gene_Ratio <- data$Count / total_genes

  # Calculate -log10(p-value) for visualization
  data$neg_log10_pvalue <- -log10(data$P.value)

  # Select top terms (by p-value significance)
  top_n <- get_config("top_n_terms", 20)
  data <- data %>%
    dplyr::arrange(P.value) %>%
    head(top_n)

  log_info(sprintf("Processed %d significant GO terms", nrow(data)))

  return(data)
}
