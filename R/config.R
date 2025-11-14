# Configuration file for Gene Ontology Analysis Visualization
# Author: jonghyeonseol
# Date: 2025-11-13

#' Global Configuration Settings
#'
#' This environment contains all configurable parameters for GO enrichment analysis
#' and visualization. Modify these values to customize the analysis pipeline.

CONFIG <- new.env(parent = emptyenv())

# Initialize configuration values
local({
  config_list <- list(
  # ===== Data Processing Parameters =====

  # Fold enrichment threshold for filtering GO terms
  # Only terms with fold enrichment >= this value will be included
  fold_enrichment_threshold = 10,

  # Number of top GO terms to display in visualizations
  # Terms are ranked by p-value significance
  top_n_terms = 20,

  # Line number where the header is located in PANTHER files
  # Default PANTHER format has header at line 12
  header_line_number = 12,

  # Line number where data starts in PANTHER files
  # Default PANTHER format has data starting at line 13
  data_start_line = 13,

  # Minimum number of lines required in input file
  # Files with fewer lines will be skipped
  min_file_lines = 12,

  # ===== Visualization Parameters =====

  # Output image format
  output_format = "png",  # Options: "png", "pdf", "svg", "jpg"

  # Output resolution (DPI) for raster images
  output_dpi = 300,

  # Plot dimensions (inches)
  plot_width = 12,
  plot_height = 8,

  # Color gradient for significance visualization
  color_low = "blue",    # Color for low significance
  color_high = "red",    # Color for high significance

  # Point size range for dotplots
  point_size_min = 3,
  point_size_max = 10,

  # Font sizes
  font_size_axis_text = 10,
  font_size_axis_title = 12,
  font_size_plot_title = 14,
  font_size_dotplot_y = 15,

  # ===== Directory Configuration =====

  # Input directory containing PANTHER enrichment files
  input_dir = "Input",

  # Output directory for all visualizations
  output_dir = "Output",

  # Subdirectory for barplots
  barplot_dir = "Output/Barplots",

  # Subdirectory for dotplots
  dotplot_dir = "Output/Dotplots",

  # ===== File Pattern Configuration =====

  # File extension for input files
  input_file_pattern = "\\.txt$",

  # ===== Validation Settings =====

  # Enable/disable strict input validation
  strict_validation = TRUE,

  # Enable/disable verbose logging
  verbose = TRUE,

  # ===== Advanced Settings =====

  # Handle fold enrichment values marked as "> 100"
  # This value will replace "> 100" strings
  fold_enrichment_ceiling = 100,

  # Sorting strategy for barplots
  # Options: "count", "pvalue", "fold_enrichment"
  barplot_sort_by = "count",

  # Sorting strategy for dotplots
  # Options: "gene_ratio", "pvalue", "fold_enrichment"
  dotplot_sort_by = "gene_ratio",

  # Secondary sort (when primary values are equal)
  secondary_sort_by = "pvalue",
  secondary_sort_order = "desc"  # "asc" or "desc"
  )

  # Assign all values to CONFIG environment
  for (key in names(config_list)) {
    CONFIG[[key]] <- config_list[[key]]
  }
})

#' Helper function to get configuration value
#'
#' @param key The configuration key to retrieve
#' @param default Default value if key is not found
#' @return The configuration value
#' @export
get_config <- function(key, default = NULL) {
  if (key %in% names(CONFIG)) {
    return(CONFIG[[key]])
  } else {
    return(default)
  }
}

#' Helper function to set configuration value
#'
#' @param key The configuration key to set
#' @param value The value to set
#' @return Invisible NULL
#' @export
set_config <- function(key, value) {
  CONFIG[[key]] <- value
  invisible(NULL)
}

#' Print current configuration
#'
#' @return Invisible NULL
#' @export
print_config <- function() {
  cat("===== Gene Ontology Analysis Configuration =====\n\n")
  config_list <- as.list(CONFIG)
  for (key in sort(names(config_list))) {
    cat(sprintf("%-30s: %s\n", key, config_list[[key]]))
  }
  cat("\n")
  invisible(NULL)
}

# Load user-specific configuration if it exists
if (file.exists("config_user.R")) {
  source("config_user.R")
  if (exists("USER_CONFIG")) {
    # Merge user configuration with default configuration
    for (key in names(USER_CONFIG)) {
      CONFIG[[key]] <- USER_CONFIG[[key]]
    }
    cat("User configuration loaded from config_user.R\n")
  }
}
