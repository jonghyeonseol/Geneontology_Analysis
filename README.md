# GeneOntologyViz <img src="https://raw.githubusercontent.com/jonghyeonseol/Geneontology_Analysis/main/man/figures/logo.png" align="right" height="139" />

<!-- badges: start -->
[![R-CMD-check](https://github.com/jonghyeonseol/Geneontology_Analysis/workflows/R-CMD-check/badge.svg)](https://github.com/jonghyeonseol/Geneontology_Analysis/actions)
[![test-coverage](https://github.com/jonghyeonseol/Geneontology_Analysis/workflows/test-coverage/badge.svg)](https://github.com/jonghyeonseol/Geneontology_Analysis/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/jonghyeonseol/Geneontology_Analysis/releases)
<!-- badges: end -->

A comprehensive R package for visualizing PANTHER GO enrichment analysis results with publication-quality plots.

## Overview

**GeneOntologyViz** processes Gene Ontology (GO) enrichment results from PANTHER and generates multiple types of professional visualizations:

- 📊 **Barplots**: Gene count per GO term
- 🎯 **Dotplots**: Gene ratio with statistical significance
- 🔥 **Heatmaps**: Cross-dataset comparison
- 🕸️ **Network Graphs**: GO term relationships

## Features

✨ **Multiple Visualization Types**
- Four distinct plot types for comprehensive analysis
- Customizable colors, sizes, and layouts
- High-resolution output (300+ DPI)

🔧 **Flexible Configuration**
- Centralized configuration system
- Easy parameter customization
- Support for multiple output formats

📦 **Complete R Package**
- Full roxygen2 documentation
- Comprehensive test suite
- CI/CD with GitHub Actions
- pkgdown website

🚀 **Production Ready**
- Input validation and error handling
- Structured logging system
- Automated pipeline function

## Installation

### From GitHub

```r
# Install devtools if needed
install.packages("devtools")

# Install GeneOntologyViz
devtools::install_github("jonghyeonseol/Geneontology_Analysis")
```

### From Source

```bash
git clone https://github.com/jonghyeonseol/Geneontology_Analysis.git
cd Geneontology_Analysis
R CMD INSTALL .
```

## Quick Start

```r
library(GeneOntologyViz)

# Run complete pipeline on all files in Input directory
run_go_pipeline()

# Custom settings
run_go_pipeline(
  input_dir = "my_data",
  output_dir = "my_results",
  create_heatmap_plots = TRUE,
  create_network_plots = TRUE
)
```

## Usage Examples

### Read and Process Data

```r
# Read PANTHER GO enrichment file
data <- read_go_results("Input/Dataset1_GOBP_Up.txt")
head(data)
```

### Create Individual Visualizations

#### Bar Plot

```r
barplot <- create_barplot(data, "GO Enrichment - GOBP Up-regulated")
print(barplot)
ggsave("barplot.png", barplot, width = 12, height = 8, dpi = 300)
```

#### Dot Plot

```r
dotplot <- create_dotplot(data, "GO Enrichment - GOBP Up-regulated")
print(dotplot)
```

#### Heatmap (Multi-dataset Comparison)

```r
# Read multiple datasets
data1 <- read_go_results("Input/Dataset1_GOBP_Up.txt")
data2 <- read_go_results("Input/Dataset2_GOBP_Up.txt")

# Create comparison heatmap
data_list <- list("Dataset1" = data1, "Dataset2" = data2)
heatmap <- create_heatmap(data_list, value_type = "pvalue")
print(heatmap)
```

#### Network Graph

```r
# Visualize GO term relationships
network <- create_network(
  data,
  similarity_threshold = 0.3,
  layout = "fr",
  node_size_by = "count"
)
print(network)
```

### Configuration

```r
# View current settings
print_config()

# Customize parameters
set_config("fold_enrichment_threshold", 15)
set_config("top_n_terms", 30)
set_config("color_low", "green")
set_config("color_high", "purple")
```

## Input Format

GeneOntologyViz expects PANTHER Overrepresentation Test output files with this structure:

```
Line 6:    Analysis Type: PANTHER Overrepresentation Test
Line 7:    Annotation Version and Release Date: GO Ontology database
Line 8:    Analyzed List: upload_1 (29) [Homo sapiens]
Line 9:    Reference List: Homo sapiens (all genes in database)
Line 10:   Test Type: FISHER
Line 11:   Correction: FDR
Line 12:   Header row with column names
Line 13+:  Data rows (tab-separated)
```

### File Naming Convention

```
Dataset{N}_{GOCAT}_{Direction}.txt
```

- **N**: Dataset number (1, 2, etc.)
- **GOCAT**: GO Category (GOBP, GOCC, GOMF)
- **Direction**: Regulation (Up or Down)

**Examples:**
- `Dataset1_GOBP_Up.txt`
- `Dataset2_GOCC_Down.txt`

## Output Structure

```
Output/
├── Barplots/          # Bar chart visualizations
├── Dotplots/          # Dot plot visualizations
├── Heatmaps/          # Cross-dataset heatmaps
└── Networks/          # GO term network graphs
```

## Documentation

- 📚 **Package Documentation**: [https://jonghyeonseol.github.io/Geneontology_Analysis/](https://jonghyeonseol.github.io/Geneontology_Analysis/)
- 📖 **Vignettes**: See `vignettes/introduction.Rmd` for detailed tutorial
- ❓ **Function Help**: `?run_go_pipeline`, `?create_barplot`, etc.

## Development

### Building Package

```r
# Install development dependencies
install.packages(c("roxygen2", "devtools", "pkgdown", "testthat"))

# Generate documentation
roxygen2::roxygenise()

# Run tests
devtools::test()

# Check package
devtools::check()

# Build package
devtools::build()
```

### Running Tests

```r
library(testthat)
library(GeneOntologyViz)

# Run all tests
test_check("GeneOntologyViz")

# Run specific test file
test_file("tests/testthat/test-heatmap.R")
```

## CI/CD

This package uses GitHub Actions for continuous integration:

- **R-CMD-check**: Tests on Ubuntu, macOS, and Windows
- **test-coverage**: Code coverage reporting with codecov
- **pkgdown**: Automatic website deployment to GitHub Pages

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Citation

If you use GeneOntologyViz in your research, please cite:

```
GeneOntologyViz: Gene Ontology Enrichment Analysis Visualization
Author: jonghyeonseol
Year: 2025
URL: https://github.com/jonghyeonseol/Geneontology_Analysis
Version: 1.0.0
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- PANTHER Classification System for GO enrichment analysis
- ggplot2 package for visualization capabilities
- R Core Team for the R programming language

## Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/jonghyeonseol/Geneontology_Analysis/issues)
- 💬 **Questions**: [GitHub Discussions](https://github.com/jonghyeonseol/Geneontology_Analysis/discussions)
- 📧 **Contact**: [your.email@example.com](mailto:your.email@example.com)

## Changelog

See [NEWS.md](NEWS.md) for version history and release notes.

---

**Version 1.0.0** | Built with ❤️ using R | © 2025 jonghyeonseol
