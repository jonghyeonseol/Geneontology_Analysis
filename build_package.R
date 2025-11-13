#!/usr/bin/env Rscript
# Package Build and Documentation Script

cat("Building GeneOntologyViz package...\n\n")

# Install required packages if not available
required_pkgs <- c("roxygen2", "devtools", "pkgdown")
for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("Installing %s...\n", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

library(roxygen2)
library(devtools)

# Generate documentation
cat("Generating documentation with roxygen2...\n")
roxygen2::roxygenise()

# Check package
cat("\nChecking package...\n")
devtools::check(document = FALSE)

# Build package
cat("\nBuilding package...\n")
devtools::build()

# Build pkgdown site
if (requireNamespace("pkgdown", quietly = TRUE)) {
  cat("\nBuilding pkgdown website...\n")
  pkgdown::build_site()
}

cat("\nPackage build complete!\n")
