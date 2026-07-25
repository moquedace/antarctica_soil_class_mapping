# Compact workflow and input contract

[← Back to the project overview](../README.md)

This directory condenses the article's analytical sequence into six principal stages plus one configuration file. It is intentionally shorter than the working research code: repeated fragments, interactive inspections, alternative models, test branches, and machine-specific paths were removed.

## Where your data enter

Create the following two inputs if adapting the workflow to another compatible study:

```text
data/
├── soil_observations.csv
└── covariates_8m/
    ├── elevation.tif
    ├── geology.tif
    ├── soil_property_01.tif
    └── ...
```

### `soil_observations.csv`

Minimum required fields:

| Column | Meaning |
|---|---|
| `X` | Point easting in the working CRS |
| `Y` | Point northing in the working CRS |
| `class_st3` | Soil-class label used as the prediction target |

Additional identifier or descriptive columns are allowed. Target labels and the working CRS are configured in [`00_config.R`](00_config.R).

### `covariates_8m/`

One GeoTIFF per predictor. All rasters must have the same:

- coordinate reference system;
- spatial resolution;
- extent and origin;
- NoData convention;
- layer names expected by the fitted models.

The filename without `.tif` becomes the predictor name.

## Processing sequence

| Stage | Script | Reads | Writes |
|---:|---|---|---|
| 0 | [`00_config.R`](00_config.R) | User-defined paths and parameters | Shared configuration objects |
| 1 | [`01_prepare_training_data.R`](01_prepare_training_data.R) | Observation CSV + covariate GeoTIFFs | Extracted model table |
| 2 | [`02_fit_rf_ensemble.R`](02_fit_rf_ensemble.R) | Model table | 100 RF models + test metrics |
| 3 | [`03_predict_class_probabilities.R`](03_predict_class_probabilities.R) | RF ensemble + covariates | Median probability map per class |
| 4 | [`04_rank_probabilities.R`](04_rank_probabilities.R) | Class-probability stack | First- to fifth-ranked classes and probabilities |
| 5 | [`05_build_mapping_units.R`](05_build_mapping_units.R) | Ranked classes + probabilities | Component count, unit code, and polygons |
| 6 | [`06_validate_outputs.R`](06_validate_outputs.R) | Main generated rasters | Structural validation report |

## Important scope note

The study inputs are not distributed. These scripts clarify the processing logic and expected interfaces; successful adaptation to another dataset still requires scientific decisions about classification, predictor preparation, sampling support, CRS, scale, and validation design.
