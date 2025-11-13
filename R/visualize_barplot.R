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
#'
#' @examples
#' \dontrun{
#' data <- read_go_results("Input/Dataset1_GOBP_Up.txt")
#' plot <- create_barplot(data, "GO Enrichment - GOBP Up-regulated")
#' print(plot)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_bar scale_fill_gradient labs theme_minimal theme element_text
#' @importFrom dplyr arrange mutate desc
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
      dplyr::arrange(!!sym(ifelse(sort_by == "count", "Count", "P.value")),
                     dplyr::desc(P.value)) %>%
      dplyr::mutate(GO_Term = factor(GO_Term, levels = GO_Term))
  } else {
    plot_data <- data %>%
      dplyr::arrange(!!sym(ifelse(sort_by == "count", "Count", "P.value")),
                     P.value) %>%
      dplyr::mutate(GO_Term = factor(GO_Term, levels = GO_Term))
  }

  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = Count, y = GO_Term, fill = neg_log10_pvalue)) +
    ggplot2::geom_bar(stat = "identity") +
    ggplot2::scale_fill_gradient(low = color_low, high = color_high, name = "-log10(p-value)") +
    ggplot2::labs(title = title,
                  x = "Gene Count",
                  y = "GO Term") +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.y = ggplot2::element_text(size = font_size_axis_text),
                   axis.text.x = ggplot2::element_text(size = font_size_axis_text),
                   axis.title = ggplot2::element_text(size = font_size_axis_title, face = "bold"),
                   plot.title = ggplot2::element_text(size = font_size_plot_title, face = "bold", hjust = 0.5),
                   legend.position = "right")

  return(p)
}
