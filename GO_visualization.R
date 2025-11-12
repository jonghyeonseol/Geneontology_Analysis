# GO Analysis Visualization using ClusterProfiler-style plots
# Author: Generated for Geneontology_Analysis
# Date: 2025-11-07

# Load required libraries
library(ggplot2)
library(dplyr)
library(stringr)

# Create output directories
dir.create("Output", showWarnings = FALSE)
dir.create("Output/Barplots", showWarnings = FALSE)
dir.create("Output/Dotplots", showWarnings = FALSE)

# Function to read and process GO enrichment results
read_go_results <- function(file_path) {
  # Read all lines
  lines <- readLines(file_path)

  # Check if file has enough lines
  if (length(lines) <= 12) {
    return(NULL)
  }

  # Extract total analyzed genes from header (line 12)
  header_line <- lines[12]
  # Pattern: upload_1 (29) - extract the number inside parentheses
  total_genes_match <- str_extract(header_line, "upload_1 \\((\\d+)\\)")
  # Extract only the number inside parentheses (not the "1" from "upload_1")
  total_genes <- as.numeric(str_extract(total_genes_match, "(?<=\\()\\d+(?=\\))"))

  # Get data lines (starting from line 13)
  data_lines <- lines[13:length(lines)]

  # Remove empty lines
  data_lines <- data_lines[data_lines != ""]

  if (length(data_lines) == 0) {
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
  data$Fold_Enrichment <- gsub("\\s*>\\s*", "", data$Fold_Enrichment)
  data$Fold_Enrichment <- suppressWarnings(as.numeric(data$Fold_Enrichment))
  data$Fold_Enrichment[is.na(data$Fold_Enrichment)] <- 100

  # Convert p-values
  data$P.value <- as.numeric(data$P.value)
  data$FDR <- as.numeric(data$FDR)

  # Remove rows with NA in critical columns
  data <- data[!is.na(data$Count) & !is.na(data$FDR), ]

  if (nrow(data) == 0) {
    return(NULL)
  }

  # Filter by Fold Enrichment threshold (>= 10)
  data <- data[data$Fold_Enrichment >= 10, ]

  if (nrow(data) == 0) {
    return(NULL)
  }

  # Calculate Gene Ratio
  data$Gene_Ratio <- data$Count / total_genes

  # Calculate -log10(p-value) for visualization
  data$neg_log10_pvalue <- -log10(data$P.value)

  # Select top terms (by p-value significance)
  data <- data %>%
    arrange(P.value) %>%
    head(20)

  return(data)
}

# Function to create barplot
create_barplot <- function(data, title) {
  if (is.null(data) || nrow(data) == 0) {
    return(NULL)
  }

  # Prepare data for plotting
  # When Count is the same, sort by p-value in descending order
  plot_data <- data %>%
    arrange(Count, desc(P.value)) %>%
    mutate(GO_Term = factor(GO_Term, levels = GO_Term))

  p <- ggplot(plot_data, aes(x = Count, y = GO_Term, fill = neg_log10_pvalue)) +
    geom_bar(stat = "identity") +
    scale_fill_gradient(low = "blue", high = "red", name = "-log10(p-value)") +
    labs(title = title,
         x = "Gene Count",
         y = "GO Term") +
    theme_minimal() +
    theme(axis.text.y = element_text(size = 10),
          axis.text.x = element_text(size = 10),
          axis.title = element_text(size = 12, face = "bold"),
          plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
          legend.position = "right")

  return(p)
}

# Function to create dotplot
create_dotplot <- function(data, title) {
  if (is.null(data) || nrow(data) == 0) {
    return(NULL)
  }

  # Prepare data for plotting (highest Gene Ratio at top - descending order)
  # When Gene_Ratio is the same, sort by p-value in descending order
  plot_data <- data %>%
    arrange(Gene_Ratio, desc(P.value)) %>%
    mutate(GO_Term = factor(GO_Term, levels = GO_Term))

  p <- ggplot(plot_data, aes(x = Gene_Ratio, y = GO_Term)) +
    geom_point(aes(size = Count, color = neg_log10_pvalue)) +
    scale_color_gradient(low = "blue", high = "red", name = "-log10(p-value)") +
    scale_size_continuous(name = "Gene Count", range = c(3, 10)) +
    labs(title = title,
         x = "Gene Ratio",
         y = "GO Term") +
    theme_minimal() +
    theme(axis.text.y = element_text(size = 15),
          axis.text.x = element_text(size = 10),
          axis.title = element_text(size = 12, face = "bold"),
          plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
          legend.position = "right")

  return(p)
}

# Main processing
input_files <- list.files("Input", pattern = "\\.txt$", full.names = TRUE)

cat("\nProcessing GO enrichment files...\n")
cat("=================================\n\n")

for (file in input_files) {
  file_name <- basename(file)
  file_base <- tools::file_path_sans_ext(file_name)

  cat(sprintf("Processing: %s\n", file_name))

  # Read and process data
  go_data <- read_go_results(file)

  if (is.null(go_data) || nrow(go_data) == 0) {
    cat(sprintf("  - No significant results found in %s\n\n", file_name))
    next
  }

  cat(sprintf("  - Found %d significant GO terms\n", nrow(go_data)))

  # Create barplot
  barplot <- create_barplot(go_data, paste("GO Enrichment -", file_base))
  if (!is.null(barplot)) {
    barplot_file <- file.path("Output/Barplots", paste0(file_base, "_barplot.png"))
    ggsave(barplot_file, barplot, width = 12, height = 8, dpi = 300)
    cat(sprintf("  - Barplot saved: %s\n", barplot_file))
  }

  # Create dotplot
  dotplot <- create_dotplot(go_data, paste("GO Enrichment -", file_base))
  if (!is.null(dotplot)) {
    dotplot_file <- file.path("Output/Dotplots", paste0(file_base, "_dotplot.png"))
    ggsave(dotplot_file, dotplot, width = 12, height = 8, dpi = 300)
    cat(sprintf("  - Dotplot saved: %s\n", dotplot_file))
  }

  cat("\n")
}

cat("All visualizations completed!\n")
cat("Results saved in Output/Barplots and Output/Dotplots directories\n")
