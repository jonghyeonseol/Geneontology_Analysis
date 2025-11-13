# Utility Functions for Gene Ontology Analysis
# Author: jonghyeonseol
# Date: 2025-11-13

#' Simple logging system
#'
#' @description Provides INFO, WARN, and ERROR level logging
#' @param level Log level (INFO, WARN, ERROR)
#' @param message Log message
#' @export
log_message <- function(level = "INFO", message) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  cat(sprintf("[%s] %s: %s\n", timestamp, level, message))
  invisible(NULL)
}

#' Log info message
#' @param message Message to log
#' @export
log_info <- function(message) {
  if (get_config("verbose", TRUE)) {
    log_message("INFO", message)
  }
}

#' Log warning message
#' @param message Message to log
#' @export
log_warn <- function(message) {
  log_message("WARN", message)
}

#' Log error message
#' @param message Message to log
#' @export
log_error <- function(message) {
  log_message("ERROR", message)
}

#' Validate input file format
#'
#' @description Checks if the file is a valid PANTHER enrichment file
#' @param file_path Path to the input file
#' @return TRUE if valid, FALSE otherwise
#' @export
validate_input_file <- function(file_path) {
  # Check if file exists
  if (!file.exists(file_path)) {
    log_error(sprintf("File not found: %s", file_path))
    return(FALSE)
  }

  # Check file size
  file_info <- file.info(file_path)
  if (file_info$size == 0) {
    log_warn(sprintf("File is empty: %s", file_path))
    return(FALSE)
  }

  # Read file content
  tryCatch({
    lines <- readLines(file_path, warn = FALSE)

    # Check minimum line count
    min_lines <- get_config("min_file_lines", 12)
    if (length(lines) <= min_lines) {
      log_warn(sprintf("File has insufficient lines (%d <= %d): %s",
                       length(lines), min_lines, basename(file_path)))
      return(FALSE)
    }

    # Check for PANTHER format signature
    if (!any(grepl("PANTHER Overrepresentation Test", lines))) {
      log_warn(sprintf("File does not appear to be PANTHER format: %s",
                       basename(file_path)))
      if (get_config("strict_validation", TRUE)) {
        return(FALSE)
      }
    }

    # Check for upload_1 pattern with gene count
    header_line <- get_config("header_line_number", 12)
    if (header_line <= length(lines)) {
      if (!grepl("upload_1 \\(\\d+\\)", lines[header_line])) {
        log_warn(sprintf("Cannot find gene count in expected header line: %s",
                         basename(file_path)))
        if (get_config("strict_validation", TRUE)) {
          return(FALSE)
        }
      }
    }

    return(TRUE)

  }, error = function(e) {
    log_error(sprintf("Error reading file %s: %s", file_path, e$message))
    return(FALSE)
  })
}

#' Sanitize file path
#'
#' @description Prevents directory traversal attacks
#' @param path File path to sanitize
#' @return Sanitized path or stops execution
#' @export
sanitize_file_path <- function(path) {
  # Check for directory traversal attempts
  if (grepl("\\.\\.", path)) {
    stop("Invalid file path: directory traversal detected")
  }

  # Normalize path
  normalized_path <- normalizePath(path, mustWork = FALSE)

  return(normalized_path)
}

#' Check required packages
#'
#' @description Verifies that all required packages are installed
#' @return TRUE if all packages are available, FALSE otherwise
#' @export
check_dependencies <- function() {
  required_packages <- c("ggplot2", "dplyr", "stringr")
  missing_packages <- c()

  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      missing_packages <- c(missing_packages, pkg)
    }
  }

  if (length(missing_packages) > 0) {
    log_error(sprintf("Missing required packages: %s",
                      paste(missing_packages, collapse = ", ")))
    log_info("Install missing packages with:")
    log_info(sprintf('  install.packages(c("%s"))',
                     paste(missing_packages, collapse = '", "')))
    return(FALSE)
  }

  return(TRUE)
}

#' Create output directories
#'
#' @description Creates necessary output directories if they don't exist
#' @export
create_output_directories <- function() {
  dirs <- c(
    get_config("output_dir", "Output"),
    get_config("barplot_dir", "Output/Barplots"),
    get_config("dotplot_dir", "Output/Dotplots")
  )

  for (dir in dirs) {
    if (!dir.exists(dir)) {
      dir.create(dir, showWarnings = FALSE, recursive = TRUE)
      log_info(sprintf("Created directory: %s", dir))
    }
  }

  invisible(NULL)
}

#' Extract GO term information
#'
#' @description Extracts GO term name and ID from full term string
#' @param full_term Full GO term string (e.g., "neutrophil aggregation (GO:0070488)")
#' @return List with go_term and go_id
#' @export
extract_go_info <- function(full_term) {
  go_term <- gsub("\\s*\\(GO:\\d+\\)", "", full_term)
  go_id <- stringr::str_extract(full_term, "GO:\\d+")

  return(list(go_term = go_term, go_id = go_id))
}

#' Format p-value for display
#'
#' @description Formats p-value in scientific notation
#' @param pvalue Numeric p-value
#' @param digits Number of significant digits
#' @return Formatted string
#' @export
format_pvalue <- function(pvalue, digits = 2) {
  if (is.na(pvalue)) return("NA")
  if (pvalue < 0.001) {
    return(sprintf("%.2e", pvalue))
  } else {
    return(sprintf("%.4f", pvalue))
  }
}

#' Validate configuration
#'
#' @description Checks if configuration values are valid
#' @return TRUE if valid, stops execution otherwise
#' @export
validate_config <- function() {
  # Check numeric parameters
  numeric_params <- c("fold_enrichment_threshold", "top_n_terms",
                      "output_dpi", "plot_width", "plot_height")

  for (param in numeric_params) {
    value <- get_config(param)
    if (!is.numeric(value) || value <= 0) {
      stop(sprintf("Invalid configuration: %s must be a positive number", param))
    }
  }

  # Check directory parameters
  input_dir <- get_config("input_dir", "Input")
  if (!dir.exists(input_dir)) {
    stop(sprintf("Input directory does not exist: %s", input_dir))
  }

  log_info("Configuration validation passed")
  return(TRUE)
}

#' Get output file path
#'
#' @description Constructs output file path based on input filename and plot type
#' @param input_filename Input file name
#' @param plot_type Type of plot ("barplot" or "dotplot")
#' @return Full output file path
#' @export
get_output_path <- function(input_filename, plot_type = "barplot") {
  file_base <- tools::file_path_sans_ext(input_filename)
  output_format <- get_config("output_format", "png")

  if (plot_type == "barplot") {
    output_dir <- get_config("barplot_dir", "Output/Barplots")
  } else {
    output_dir <- get_config("dotplot_dir", "Output/Dotplots")
  }

  output_file <- file.path(output_dir,
                           paste0(file_base, "_", plot_type, ".", output_format))

  return(output_file)
}

#' Print session information
#'
#' @description Prints R version and package versions for reproducibility
#' @export
print_session_info <- function() {
  log_info("===== Session Information =====")
  log_info(sprintf("R version: %s", R.version.string))
  log_info(sprintf("ggplot2: %s", packageVersion("ggplot2")))
  log_info(sprintf("dplyr: %s", packageVersion("dplyr")))
  log_info(sprintf("stringr: %s", packageVersion("stringr")))
  log_info("==============================")
  invisible(NULL)
}
