#!/usr/bin/env Rscript
# Quick pipeline runner script
# Usage: source("run_pipeline.R") or Rscript run_pipeline.R

# Set working directory to package root
setwd("/Users/seoljonghyeon/Documents/GitHub/Geneontology_Analysis")

# Method 1: Load as package (recommended)
cat("Loading GeneOntologyViz package...\n")
library(devtools)
load_all()

# Run pipeline
cat("\n🚀 Running GO Analysis Pipeline...\n\n")
run_go_pipeline()

cat("\n✅ Done! Check Output/ directory for results.\n")
