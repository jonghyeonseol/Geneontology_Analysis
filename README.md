# Gene Ontology Analysis Visualization

A bioinformatics tool for visualizing PANTHER GO enrichment analysis results with publication-quality plots.

## Overview

This R-based pipeline processes Gene Ontology (GO) enrichment results from PANTHER and generates two types of visualizations:
- **Barplots**: Display gene count per GO term
- **Dotplots**: Display gene ratio vs GO terms with statistical significance

## Features

- Automatic processing of multiple GO enrichment files
- Filtering by fold enrichment threshold (default: ≥10)
- Top 20 most significant GO terms selection
- High-resolution output (300 DPI PNG images)
- Support for three GO categories: GOBP, GOCC, GOMF
- Handles both up-regulated and down-regulated gene sets

## Requirements

### R Version
- R >= 4.0.0

### Required Packages
```r
install.packages(c("ggplot2", "dplyr", "stringr"))
```

## Installation

1. Clone this repository:
```bash
git clone <repository-url>
cd Geneontology_Analysis
```

2. Install required R packages:
```r
install.packages(c("ggplot2", "dplyr", "stringr"))
```

## Usage

### Input Data Format

Place your PANTHER GO enrichment analysis files in the `Input/` directory. Files should follow this naming convention:
```
Dataset{N}_{GOCAT}_{Direction}.txt
```

Where:
- `N`: Dataset number (e.g., 1, 2)
- `GOCAT`: GO Category (GOBP, GOCC, or GOMF)
- `Direction`: Regulation direction (Up or Down)

Example: `Dataset1_GOBP_Up.txt`

### Input File Structure

Files must be tab-separated text files from PANTHER Overrepresentation Test with:
- Line 6: Analysis Type
- Line 7: Annotation Version
- Line 8: Analyzed List with gene count (e.g., "upload_1 (29)")
- Line 9: Reference List
- Line 10: Test Type (FISHER)
- Line 11: Correction (FDR)
- Line 12: Header row
- Line 13+: Data rows

### Running the Analysis

```r
source("GO_visualization.R")
```

The script will:
1. Read all `.txt` files from the `Input/` directory
2. Process and filter GO enrichment results
3. Generate visualizations
4. Save outputs to `Output/Barplots/` and `Output/Dotplots/`

### Output

Generated PNG files will be saved in:
- `Output/Barplots/` - Bar chart visualizations
- `Output/Dotplots/` - Dot plot visualizations

Output files follow the naming pattern:
```
{InputFileName}_barplot.png
{InputFileName}_dotplot.png
```

## Configuration

### Adjustable Parameters

You can modify these settings in the script:

- **Fold Enrichment Threshold**: Line 78 (`data$Fold_Enrichment >= 10`)
- **Number of Top Terms**: Line 93 (`head(20)`)
- **Output Resolution**: Line 181, 189 (`dpi = 300`)
- **Plot Dimensions**: Line 181, 189 (`width = 12, height = 8`)

## Example Output

### Barplot
Shows absolute gene counts for each GO term, colored by statistical significance (-log10 p-value).

### Dotplot
Shows gene ratio (proportion of analyzed genes) sized by gene count and colored by significance.

## Data Filtering

The pipeline applies the following filters:
1. Fold enrichment ≥ 10 (configurable)
2. Valid numeric values for Count and FDR
3. Top 20 terms by p-value significance

## Troubleshooting

### "No significant results found"
- Check that your input file has more than 12 lines
- Verify fold enrichment values meet the threshold (≥10)
- Ensure the file format matches PANTHER output specifications

### Missing visualizations
- Ensure the `Output/` directory has write permissions
- Check that required R packages are installed
- Verify input data contains valid GO enrichment results

## Project Structure

```
Geneontology_Analysis/
├── GO_visualization.R          # Main analysis script
├── config.R                    # Configuration settings
├── LICENSE                     # MIT License
├── README.md                   # This file
├── .gitignore                  # Git ignore rules
├── Input/                      # Input data directory
│   └── *.txt                   # PANTHER GO enrichment files
├── Output/
│   ├── Barplots/              # Generated bar charts
│   └── Dotplots/              # Generated dot plots
└── tests/                      # Unit tests (if available)
```

## Citation

If you use this tool in your research, please cite:

```
Gene Ontology Analysis Visualization Tool
Author: jonghyeonseol
Year: 2025
License: MIT
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and questions:
- Open an issue in the GitHub repository
- Check existing issues for solutions

## Changelog

### Version 0.1.0 (2025-11-07)
- Initial release
- Support for PANTHER GO enrichment visualization
- Barplot and dotplot generation
- Automatic filtering and ranking

## Author

jonghyeonseol

## Acknowledgments

- PANTHER Classification System for GO enrichment analysis
- ggplot2 package for visualization capabilities
