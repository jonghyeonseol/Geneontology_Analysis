# Test runner for Gene Ontology Analysis
# This file is used by R CMD check and testthat::test_dir()

library(testthat)

# Source the main files
source("../../config.R")
source("../../utils.R")
source("../../GO_visualization.R")

# Run all tests
test_check("GeneOntologyViz")
