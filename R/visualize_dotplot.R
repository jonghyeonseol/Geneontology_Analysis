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
#'
#' @examples
#' \dontrun{
#' data <- read_go_results("Input/Dataset1_GOBP_Up.txt")
#' plot <- create_dotplot(data, "GO Enrichment - GOBP Up-regulated")
#' print(plot)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_point scale_color_gradient scale_size_continuous labs theme_minimal theme element_text
#' @importFrom dplyr arrange mutate desc
#' @importFrom rlang sym
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
      dplyr::arrange(!!rlang::sym(ifelse(sort_by == "gene_ratio", "Gene_Ratio", "P.value")),
                     dplyr::desc(P.value)) %>%
      dplyr::mutate(GO_Term = factor(GO_Term, levels = GO_Term))
  } else {
    plot_data <- data %>%
      dplyr::arrange(!!rlang::sym(ifelse(sort_by == "gene_ratio", "Gene_Ratio", "P.value")),
                     P.value) %>%
      dplyr::mutate(GO_Term = factor(GO_Term, levels = GO_Term))
  }

  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = Gene_Ratio, y = GO_Term)) +
    ggplot2::geom_point(ggplot2::aes(size = Count, color = neg_log10_pvalue)) +
    ggplot2::scale_color_gradient(low = color_low, high = color_high, name = "-log10(p-value)") +
    ggplot2::scale_size_continuous(name = "Gene Count", range = c(point_size_min, point_size_max)) +
    ggplot2::labs(title = title,
                  x = "Gene Ratio",
                  y = "GO Term") +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.y = ggplot2::element_text(size = font_size_dotplot_y),
                   axis.text.x = ggplot2::element_text(size = font_size_axis_text),
                   axis.title = ggplot2::element_text(size = font_size_axis_title, face = "bold"),
                   plot.title = ggplot2::element_text(size = font_size_plot_title, face = "bold", hjust = 0.5),
                   legend.position = "right")

  return(p)
}
