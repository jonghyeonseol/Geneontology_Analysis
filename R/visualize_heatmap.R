#' Create Heatmap for GO Enrichment Comparison
#'
#' @description Creates a heatmap showing GO term enrichment across multiple datasets
#' @param data_list Named list of data frames with processed GO enrichment results
#' @param value_type Type of value to display: "pvalue", "fold_enrichment", or "count" (default: "pvalue")
#' @param cluster_rows Logical, whether to cluster rows (GO terms) (default: TRUE)
#' @param cluster_cols Logical, whether to cluster columns (datasets) (default: TRUE)
#' @param title Plot title (default: "GO Enrichment Heatmap")
#' @return ggplot2 object or NULL if data is invalid
#' @export
#'
#' @details
#' The heatmap displays:
#' \itemize{
#'   \item Rows: GO terms
#'   \item Columns: Datasets
#'   \item Cell color: -log10(p-value), fold enrichment, or gene count
#'   \item Hierarchical clustering of rows and columns (optional)
#' }
#'
#' @examples
#' \dontrun{
#' data1 <- read_go_results("Input/Dataset1_GOBP_Up.txt")
#' data2 <- read_go_results("Input/Dataset2_GOBP_Up.txt")
#' data_list <- list("Dataset1" = data1, "Dataset2" = data2)
#' plot <- create_heatmap(data_list, value_type = "pvalue")
#' print(plot)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_tile scale_fill_gradient2 labs theme_minimal theme element_text coord_fixed
#' @importFrom dplyr select mutate
#' @importFrom tidyr pivot_wider replace_na
create_heatmap <- function(data_list,
                           value_type = "pvalue",
                           cluster_rows = TRUE,
                           cluster_cols = TRUE,
                           title = "GO Enrichment Heatmap") {

  if (is.null(data_list) || length(data_list) == 0) {
    log_warn("No data available for heatmap")
    return(NULL)
  }

  # Check if all elements are data frames
  valid_data <- sapply(data_list, function(x) !is.null(x) && is.data.frame(x) && nrow(x) > 0)

  if (!any(valid_data)) {
    log_warn("No valid data frames in data_list")
    return(NULL)
  }

  # Filter to valid data only
  data_list <- data_list[valid_data]

  # Extract dataset names
  dataset_names <- names(data_list)
  if (is.null(dataset_names)) {
    dataset_names <- paste0("Dataset", seq_along(data_list))
    names(data_list) <- dataset_names
  }

  # Combine all data
  combined_data <- list()
  for (dataset_name in dataset_names) {
    df <- data_list[[dataset_name]]

    # Select appropriate value column
    if (value_type == "pvalue") {
      df$value <- df$neg_log10_pvalue
      value_label <- "-log10(p-value)"
    } else if (value_type == "fold_enrichment") {
      df$value <- log2(df$Fold_Enrichment)
      value_label <- "log2(Fold Enrichment)"
    } else if (value_type == "count") {
      df$value <- df$Count
      value_label <- "Gene Count"
    } else {
      log_warn(sprintf("Unknown value_type: %s, using pvalue", value_type))
      df$value <- df$neg_log10_pvalue
      value_label <- "-log10(p-value)"
    }

    df$dataset <- dataset_name
    df <- df[, c("GO_Term", "dataset", "value")]
    combined_data[[dataset_name]] <- df
  }

  # Merge all datasets
  all_data <- do.call(rbind, combined_data)

  # Create wide format matrix
  matrix_data <- tidyr::pivot_wider(all_data,
                                     names_from = dataset,
                                     values_from = value,
                                     values_fill = 0)

  # Extract GO terms
  go_terms <- matrix_data$GO_Term

  # Convert to matrix
  mat <- as.matrix(matrix_data[, -1])
  rownames(mat) <- go_terms

  # Perform clustering if requested
  row_order <- seq_len(nrow(mat))
  col_order <- seq_len(ncol(mat))

  if (cluster_rows && nrow(mat) > 1) {
    tryCatch({
      hc_row <- hclust(dist(mat))
      row_order <- hc_row$order
    }, error = function(e) {
      log_warn("Failed to cluster rows, using original order")
    })
  }

  if (cluster_cols && ncol(mat) > 1) {
    tryCatch({
      hc_col <- hclust(dist(t(mat)))
      col_order <- hc_col$order
    }, error = function(e) {
      log_warn("Failed to cluster columns, using original order")
    })
  }

  # Reorder matrix
  mat <- mat[row_order, col_order, drop = FALSE]

  # Convert back to long format for ggplot
  plot_data <- as.data.frame(mat)
  plot_data$GO_Term <- rownames(mat)
  plot_data <- tidyr::pivot_longer(plot_data,
                                    cols = -GO_Term,
                                    names_to = "Dataset",
                                    values_to = "Value")

  # Set factor levels to maintain order
  plot_data$GO_Term <- factor(plot_data$GO_Term, levels = rownames(mat))
  plot_data$Dataset <- factor(plot_data$Dataset, levels = colnames(mat))

  # Get configuration
  font_size_axis_text <- get_config("font_size_axis_text", 10)
  font_size_axis_title <- get_config("font_size_axis_title", 12)
  font_size_plot_title <- get_config("font_size_plot_title", 14)

  # Create heatmap
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = Dataset, y = GO_Term, fill = Value)) +
    ggplot2::geom_tile(color = "white", size = 0.5) +
    ggplot2::scale_fill_gradient2(
      low = "white",
      mid = "yellow",
      high = "red",
      midpoint = max(plot_data$Value) / 2,
      name = value_label
    ) +
    ggplot2::labs(
      title = title,
      x = "Dataset",
      y = "GO Term"
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = font_size_axis_text),
      axis.text.y = ggplot2::element_text(size = font_size_axis_text),
      axis.title = ggplot2::element_text(size = font_size_axis_title, face = "bold"),
      plot.title = ggplot2::element_text(size = font_size_plot_title, face = "bold", hjust = 0.5),
      legend.position = "right"
    ) +
    ggplot2::coord_fixed()

  log_info(sprintf("Created heatmap with %d GO terms and %d datasets",
                   length(unique(plot_data$GO_Term)),
                   length(unique(plot_data$Dataset))))

  return(p)
}
