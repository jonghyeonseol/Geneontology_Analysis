#' Run Complete GO Enrichment Visualization Pipeline
#'
#' @description Main function to process all GO enrichment files and generate visualizations
#' @param input_dir Directory containing input PANTHER enrichment files (default: "Input")
#' @param output_dir Base directory for output files (default: "Output")
#' @param create_heatmap_plots Logical, whether to create heatmap comparisons (default: TRUE)
#' @param create_network_plots Logical, whether to create network graphs (default: TRUE)
#' @param verbose Logical, whether to print progress messages (default: TRUE)
#' @return Invisible list of processing results
#' @export
#'
#' @examples
#' \dontrun{
#' # Run complete pipeline
#' run_go_pipeline()
#'
#' # Run with custom settings
#' run_go_pipeline(input_dir = "my_data", create_network_plots = FALSE)
#' }
#'
#' @importFrom ggplot2 ggsave
run_go_pipeline <- function(input_dir = "Input",
                             output_dir = "Output",
                             create_heatmap_plots = TRUE,
                             create_network_plots = TRUE,
                             verbose = TRUE) {

  # Set verbose mode
  set_config("verbose", verbose)

  # Print session info
  if (verbose) {
    print_session_info()
  }

  # Check dependencies
  if (!check_dependencies()) {
    stop("Missing required packages. Please install them before continuing.")
  }

  # Update configuration
  set_config("input_dir", input_dir)
  set_config("output_dir", output_dir)

  # Validate configuration
  validate_config()

  # Create output directories
  create_output_directories()

  # Also create directories for new visualizations
  if (create_heatmap_plots) {
    heatmap_dir <- file.path(output_dir, "Heatmaps")
    if (!dir.exists(heatmap_dir)) {
      dir.create(heatmap_dir, showWarnings = FALSE, recursive = TRUE)
      log_info(sprintf("Created directory: %s", heatmap_dir))
    }
  }

  if (create_network_plots) {
    network_dir <- file.path(output_dir, "Networks")
    if (!dir.exists(network_dir)) {
      dir.create(network_dir, showWarnings = FALSE, recursive = TRUE)
      log_info(sprintf("Created directory: %s", network_dir))
    }
  }

  # Get input files
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
  # Only store results in memory if heatmaps are needed
  results_list <- if (create_heatmap_plots) list() else NULL

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

    # Store results for later heatmap generation (only if needed)
    if (create_heatmap_plots) {
      results_list[[file_base]] <- go_data
    }

    # Create barplot
    barplot <- create_barplot(go_data, paste("GO Enrichment -", file_base))
    if (!is.null(barplot)) {
      barplot_file <- get_output_path(file_name, "barplot")
      ggplot2::ggsave(barplot_file, barplot,
                      width = get_config("plot_width", 12),
                      height = get_config("plot_height", 8),
                      dpi = get_config("output_dpi", 300))
      log_info(sprintf("Barplot saved: %s", barplot_file))
    }
    barplot <- NULL  # Free memory

    # Create dotplot
    dotplot <- create_dotplot(go_data, paste("GO Enrichment -", file_base))
    if (!is.null(dotplot)) {
      dotplot_file <- get_output_path(file_name, "dotplot")
      ggplot2::ggsave(dotplot_file, dotplot,
                      width = get_config("plot_width", 12),
                      height = get_config("plot_height", 8),
                      dpi = get_config("output_dpi", 300))
      log_info(sprintf("Dotplot saved: %s", dotplot_file))
    }
    dotplot <- NULL  # Free memory

    # Create network plot
    if (create_network_plots && nrow(go_data) >= 2) {
      network_plot <- create_network(go_data,
                                      similarity_threshold = 0.3,
                                      title = paste("GO Term Network -", file_base))
      if (!is.null(network_plot)) {
        network_file <- file.path(output_dir, "Networks", paste0(file_base, "_network.png"))
        ggplot2::ggsave(network_file, network_plot,
                        width = get_config("plot_width", 12),
                        height = get_config("plot_height", 12),
                        dpi = get_config("output_dpi", 300))
        log_info(sprintf("Network plot saved: %s", network_file))
      }
      network_plot <- NULL  # Free memory
    }

    # If not storing for heatmap, free go_data too
    if (!create_heatmap_plots) {
      go_data <- NULL
    }

    processed_count <- processed_count + 1
    log_info("")

    # Periodic garbage collection for large datasets
    if (processed_count %% 10 == 0) {
      gc(verbose = FALSE)
    }
  }

  # Create heatmaps for grouped comparisons
  if (create_heatmap_plots && !is.null(results_list) && length(results_list) >= 2) {
    log_info("=================================")
    log_info("Creating heatmap comparisons...")

    # Group by GO category (GOBP, GOCC, GOMF)
    categories <- c("GOBP", "GOCC", "GOMF")
    directions <- c("Up", "Down")

    for (cat in categories) {
      for (dir in directions) {
        # Find matching datasets
        pattern <- sprintf("_%s_%s", cat, dir)
        matching_names <- names(results_list)[grepl(pattern, names(results_list))]

        if (length(matching_names) >= 2) {
          heatmap_data <- results_list[matching_names]
          heatmap_plot <- create_heatmap(heatmap_data,
                                          value_type = "pvalue",
                                          title = sprintf("GO Enrichment Heatmap - %s %s-regulated", cat, dir))

          if (!is.null(heatmap_plot)) {
            heatmap_file <- file.path(output_dir, "Heatmaps",
                                       sprintf("%s_%s_heatmap.png", cat, dir))
            ggplot2::ggsave(heatmap_file, heatmap_plot,
                            width = 10 + length(matching_names) * 2,
                            height = 12,
                            dpi = get_config("output_dpi", 300))
            log_info(sprintf("Heatmap saved: %s", heatmap_file))
          }
        }
      }
    }
  }

  # Summary
  log_info("=================================")
  log_info("Processing Summary:")
  log_info(sprintf("  Total files: %d", length(input_files)))
  log_info(sprintf("  Successfully processed: %d", processed_count))
  log_info(sprintf("  Skipped: %d", skipped_count))
  log_info("=================================")
  log_info("All visualizations completed!")
  log_info(sprintf("Results saved in %s", output_dir))

  invisible(results_list)
}


#' GeneOntologyViz Package
#'
#' @description
#' A comprehensive R package for visualizing PANTHER GO enrichment analysis results.
#'
#' @details
#' The package provides multiple visualization types:
#' \itemize{
#'   \item Barplots: Gene count per GO term
#'   \item Dotplots: Gene ratio with significance
#'   \item Heatmaps: Cross-dataset comparisons
#'   \item Network graphs: GO term relationships
#' }
#'
#' @section Main Functions:
#' \itemize{
#'   \item \code{\link{run_go_pipeline}}: Run complete analysis pipeline
#'   \item \code{\link{read_go_results}}: Read and process GO enrichment files
#'   \item \code{\link{create_barplot}}: Create bar plot visualization
#'   \item \code{\link{create_dotplot}}: Create dot plot visualization
#'   \item \code{\link{create_heatmap}}: Create heatmap comparison
#'   \item \code{\link{create_network}}: Create network graph
#' }
#'
#' @section Configuration:
#' Use \code{\link{get_config}} and \code{\link{set_config}} to customize analysis parameters.
#'
#' @docType package
#' @name GeneOntologyViz
#' @aliases GeneOntologyViz-package
NULL
