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
#' head(data)
#' }
#'
#' @importFrom stringr str_extract
#' @importFrom dplyr arrange mutate
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
  total_genes_match <- stringr::str_extract(header_line_text, "upload_1 \\((\\d+)\\)")
  # Extract only the number inside parentheses (not the "1" from "upload_1")
  total_genes <- as.numeric(stringr::str_extract(total_genes_match, "(?<=\\()\\d+(?=\\))"))

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
    dplyr::arrange(P.value) %>%
    head(top_n)

  log_info(sprintf("Processed %d significant GO terms", nrow(data)))

  return(data)
}
