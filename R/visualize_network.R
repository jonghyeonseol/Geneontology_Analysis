#' Create Network Graph for GO Enrichment
#'
#' @description Creates a network graph showing relationships between GO terms
#' @param data Data frame with processed GO enrichment results
#' @param similarity_threshold Minimum similarity score to create an edge (default: 0.3)
#' @param layout Layout algorithm: "fr" (Fruchterman-Reingold), "kk" (Kamada-Kawai), "circle", "star" (default: "fr")
#' @param node_size_by Node size based on: "count", "pvalue", or "fold_enrichment" (default: "count")
#' @param edge_width_by Edge width based on: "similarity" (default: "similarity")
#' @param title Plot title (default: "GO Term Network")
#' @return ggplot2 object or NULL if data is invalid
#' @export
#'
#' @details
#' The network graph displays:
#' \itemize{
#'   \item Nodes: GO terms
#'   \item Node size: Based on gene count, p-value, or fold enrichment
#'   \item Node color: -log10(p-value)
#'   \item Edges: Connect terms with semantic similarity above threshold
#'   \item Edge width: Proportional to similarity score
#' }
#'
#' @examples
#' \dontrun{
#' data <- read_go_results("Input/Dataset1_GOBP_Up.txt")
#' plot <- create_network(data, similarity_threshold = 0.3, layout = "fr")
#' print(plot)
#' }
#'
#' @importFrom ggplot2 ggplot aes geom_segment geom_point geom_text scale_color_gradient scale_size_continuous labs theme_void theme element_text
create_network <- function(data,
                           similarity_threshold = 0.3,
                           layout = "fr",
                           node_size_by = "count",
                           edge_width_by = "similarity",
                           title = "GO Term Network") {

  if (is.null(data) || nrow(data) == 0) {
    log_warn("No data available for network graph")
    return(NULL)
  }

  if (nrow(data) < 2) {
    log_warn("Need at least 2 GO terms for network graph")
    return(NULL)
  }

  # Calculate similarity matrix based on term overlap
  # For simplicity, we'll use Jaccard similarity based on word overlap in GO term names
  n_terms <- nrow(data)
  similarity_matrix <- matrix(0, nrow = n_terms, ncol = n_terms)
  rownames(similarity_matrix) <- data$GO_Term
  colnames(similarity_matrix) <- data$GO_Term

  # Calculate word-based similarity
  for (i in 1:(n_terms - 1)) {
    words_i <- tolower(strsplit(data$GO_Term[i], " ")[[1]])
    for (j in (i + 1):n_terms) {
      words_j <- tolower(strsplit(data$GO_Term[j], " ")[[1]])

      # Jaccard similarity
      intersection <- length(intersect(words_i, words_j))
      union <- length(union(words_i, words_j))

      if (union > 0) {
        similarity <- intersection / union
        similarity_matrix[i, j] <- similarity
        similarity_matrix[j, i] <- similarity
      }
    }
  }

  # Create edge list
  edges <- data.frame()
  for (i in 1:(n_terms - 1)) {
    for (j in (i + 1):n_terms) {
      if (similarity_matrix[i, j] >= similarity_threshold) {
        edges <- rbind(edges, data.frame(
          from = i,
          to = j,
          similarity = similarity_matrix[i, j]
        ))
      }
    }
  }

  if (nrow(edges) == 0) {
    log_warn(sprintf("No edges found with similarity >= %.2f. Try lowering the threshold.", similarity_threshold))
    return(NULL)
  }

  log_info(sprintf("Created network with %d nodes and %d edges", n_terms, nrow(edges)))

  # Create node positions using layout algorithm
  # Simple force-directed layout simulation
  set.seed(42)  # For reproducibility

  if (layout == "circle") {
    # Circular layout
    angles <- seq(0, 2 * pi, length.out = n_terms + 1)[1:n_terms]
    node_positions <- data.frame(
      id = 1:n_terms,
      x = cos(angles),
      y = sin(angles)
    )
  } else if (layout == "star") {
    # Star layout (first node in center)
    angles <- seq(0, 2 * pi, length.out = n_terms)
    node_positions <- data.frame(
      id = 1:n_terms,
      x = c(0, 0.8 * cos(angles[-1])),
      y = c(0, 0.8 * sin(angles[-1]))
    )
  } else {
    # Force-directed layout (simplified Fruchterman-Reingold)
    node_positions <- data.frame(
      id = 1:n_terms,
      x = runif(n_terms, -1, 1),
      y = runif(n_terms, -1, 1)
    )

    # Simple force-directed iterations
    for (iter in 1:50) {
      # Repulsive forces between all nodes
      for (i in 1:n_terms) {
        for (j in 1:n_terms) {
          if (i != j) {
            dx <- node_positions$x[i] - node_positions$x[j]
            dy <- node_positions$y[i] - node_positions$y[j]
            dist <- sqrt(dx^2 + dy^2) + 0.01

            # Repulsion
            force <- 0.1 / dist^2
            node_positions$x[i] <- node_positions$x[i] + force * dx / dist
            node_positions$y[i] <- node_positions$y[i] + force * dy / dist
          }
        }
      }

      # Attractive forces along edges
      for (e in 1:nrow(edges)) {
        i <- edges$from[e]
        j <- edges$to[e]

        dx <- node_positions$x[j] - node_positions$x[i]
        dy <- node_positions$y[j] - node_positions$y[i]
        dist <- sqrt(dx^2 + dy^2) + 0.01

        # Attraction
        force <- dist^2 * 0.01 * edges$similarity[e]
        node_positions$x[i] <- node_positions$x[i] + force * dx / dist
        node_positions$y[i] <- node_positions$y[i] - force * dy / dist
        node_positions$x[j] <- node_positions$x[j] - force * dx / dist
        node_positions$y[j] <- node_positions$y[j] + force * dy / dist
      }

      # Center and scale
      node_positions$x <- scale(node_positions$x)[, 1]
      node_positions$y <- scale(node_positions$y)[, 1]
    }
  }

  # Prepare edge data for plotting
  edge_data <- edges
  edge_data$x <- node_positions$x[edges$from]
  edge_data$y <- node_positions$y[edges$from]
  edge_data$xend <- node_positions$x[edges$to]
  edge_data$yend <- node_positions$y[edges$to]

  # Prepare node data
  node_data <- data.frame(
    id = 1:n_terms,
    x = node_positions$x,
    y = node_positions$y,
    GO_Term = data$GO_Term,
    Count = data$Count,
    pvalue = data$neg_log10_pvalue,
    Fold_Enrichment = data$Fold_Enrichment
  )

  # Determine node size
  if (node_size_by == "pvalue") {
    node_data$size <- node_data$pvalue
  } else if (node_size_by == "fold_enrichment") {
    node_data$size <- log2(node_data$Fold_Enrichment)
  } else {
    node_data$size <- node_data$Count
  }

  # Get configuration
  font_size_plot_title <- get_config("font_size_plot_title", 14)

  # Create network plot
  p <- ggplot2::ggplot() +
    # Draw edges
    ggplot2::geom_segment(data = edge_data,
                          ggplot2::aes(x = x, y = y, xend = xend, yend = yend, alpha = similarity),
                          color = "gray70", size = 0.5) +
    # Draw nodes
    ggplot2::geom_point(data = node_data,
                        ggplot2::aes(x = x, y = y, size = size, color = pvalue),
                        alpha = 0.8) +
    # Add labels (for small networks)
    {
      if (n_terms <= 20) {
        ggplot2::geom_text(data = node_data,
                           ggplot2::aes(x = x, y = y, label = GO_Term),
                           size = 3, hjust = 0.5, vjust = -1, check_overlap = TRUE)
      }
    } +
    ggplot2::scale_color_gradient(low = "blue", high = "red", name = "-log10(p-value)") +
    ggplot2::scale_size_continuous(name = node_size_by, range = c(3, 10)) +
    ggplot2::scale_alpha_continuous(range = c(0.3, 1), guide = "none") +
    ggplot2::labs(title = title) +
    ggplot2::theme_void() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(size = font_size_plot_title, face = "bold", hjust = 0.5),
      legend.position = "right"
    )

  return(p)
}
