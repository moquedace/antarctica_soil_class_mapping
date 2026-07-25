# Computational provenance and execution context

[← Back to the project overview](../README.md)

This is a code-only companion to the article. Its purpose is to show the analytical sequence, expose the implementation choices, and connect each processing stage to the published maps. It does not distribute the source observations, environmental covariates, intermediate rasters, or original processing environment.

## What this repository provides

- a compact implementation of the principal transformations in the published analysis;
- the order and dependency relationships among processing stages;
- model parameters and decision rules visible in code;
- documentation linking scripts to the article and Zenodo products;
- machine-readable citation metadata.

## What this repository does not provide

- the soil-profile training table;
- the complete 8 m environmental covariate stack;
- geological, terrain, Sentinel-2, and soil-property source layers;
- intermediate model objects or per-run prediction rasters;
- a frozen computing environment or one-command reproduction workflow.

The absence of these inputs is intentional. Final spatial products are distributed separately through [Zenodo](https://zenodo.org/records/19475873), while methodological interpretation remains anchored in the peer-reviewed article.

## Software visible in the workflow

The compact public scripts directly depend on `caret`, `dplyr`, and `terra`; these dependencies and the minimum R version are declared in [`DESCRIPTION`](../DESCRIPTION).

The broader research workflow documented by the article and preserved in the original working archive also used packages including:

- spatial processing: `terra`, `sf`, `RSAGA`;
- modeling and validation: `caret`, `randomForest`, `e1071`;
- parallel processing: `parallel`, `parallelly`, `doParallel`, `foreach`;
- data handling: `dplyr`, `tidyr`, `purrr`, `readr`, `stringr`, `data.table`, `tibble`;
- figures and summaries: `ggplot2`, `DescTools`.

Some processing stages use helper functions from [`moquedace/funcs`](https://github.com/moquedace/funcs). These references are retained because they form part of the computational history of the study.

## Original processing context

Relative paths in the scripts reveal the logical organization used during analysis:

```text
project/
├── dataset/               # Soil observations and class labels
├── reproject/             # Aligned 8 m environmental covariates
├── shapes/                # Study-area masks and vector support data
├── tiles_covariaveis/     # Covariate tiles for spatial prediction
├── extract_xy/            # Extracted model tables
├── rf/                    # Models and probability predictions
├── figures/               # Derived figures
└── scripts/               # Ordered analytical code
```

This tree documents how files moved through the analysis. Empty versions of these directories are not included because they would not make the workflow independently executable.

## How to read the sequence

1. `00_config.R` defines the data interfaces and method parameters.
2. Script 01 combines user-supplied point observations with an aligned predictor stack.
3. Script 02 filters predictors and fits the repeated Random Forest ensemble.
4. Script 03 produces median soil-class probabilities across model runs.
5. Script 04 ranks the plausible classes and their probabilities at each pixel.
6. Script 05 converts cumulative probability into soil mapping units.
7. Script 06 validates the structure of the main raster outputs.

Use the [curated script index](../scripts/README.md) for file-level descriptions and [Methods and code](methods-and-code.md) for correspondence with the article.

## Interpretation boundary

The code clarifies what was done and where compatible user data would enter, but code availability alone is not equivalent to full computational reproducibility. Users should cite the article for methodological interpretation and the Zenodo record when using the resulting spatial products.
