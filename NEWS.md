# GeneOntologyViz 1.0.0

## Major Features

* Complete package refactoring with proper R package structure
* **New Visualizations:**
  * Heatmap visualization for cross-dataset comparison (`create_heatmap()`)
  * Network graph visualization for GO term relationships (`create_network()`)
* Full roxygen2 documentation for all functions
* Comprehensive test suite with testthat
* Automated pipeline function (`run_go_pipeline()`)

## Improvements

* Centralized configuration system (`config.R`)
* Enhanced input validation and error handling
* Structured logging system
* Better code organization with modular design
* Support for multiple output formats

## Infrastructure

* Added GitHub Actions CI/CD workflows
* Added pkgdown website generation
* Added test coverage reporting
* Proper NAMESPACE management

## Bug Fixes

* Fixed fold enrichment handling for "> 100" values
* Improved file path sanitization
* Better handling of empty or invalid input files

## Documentation

* Added comprehensive README with usage examples
* Added function documentation with roxygen2
* Added package vignette
* Added NEWS.md for version tracking

---

# GeneOntologyViz 0.1.0

## Initial Release

* Basic GO enrichment visualization
* Barplot and dotplot generation
* Processing of PANTHER enrichment files
* Support for GOBP, GOCC, GOMF categories
