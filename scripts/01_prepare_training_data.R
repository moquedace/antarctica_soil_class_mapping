# Stage 1 — observations + covariates -> model-ready table -------------------
#
# User inputs:
#   data/soil_observations.csv
#     Required columns: X, Y, class_st3
#   data/covariates_8m/*.tif
#     One aligned GeoTIFF per environmental covariate
#
# Output:
#   derived/training_table.csv

source("scripts/00_config.R")

required_packages <- c("terra", "dplyr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0) {
  stop("Install required packages: ", paste(missing_packages, collapse = ", "))
}

if (!file.exists(paths$observations)) {
  stop("Add the point table at: ", paths$observations)
}
if (!dir.exists(paths$covariates)) {
  stop("Add the aligned covariate rasters at: ", paths$covariates)
}

observations <- utils::read.csv(paths$observations, check.names = FALSE)
required_columns <- c(settings$coordinate_columns, settings$target)
missing_columns <- setdiff(required_columns, names(observations))
if (length(missing_columns) > 0) {
  stop("Missing observation columns: ", paste(missing_columns, collapse = ", "))
}

covariate_files <- list.files(
  paths$covariates,
  pattern = "\\.tif$",
  full.names = TRUE
)
if (length(covariate_files) == 0) {
  stop("No GeoTIFF covariates found in: ", paths$covariates)
}

covariates <- terra::rast(covariate_files)
names(covariates) <- tools::file_path_sans_ext(basename(covariate_files))

geometry_matches <- vapply(
  seq_len(terra::nlyr(covariates)),
  function(i) terra::compareGeom(
    covariates[[1]], covariates[[i]], stopOnError = FALSE
  ),
  logical(1)
)
if (!all(geometry_matches)) {
  stop("Covariates must share CRS, extent, resolution, and origin.")
}

points <- terra::vect(
  observations,
  geom = settings$coordinate_columns,
  crs = settings$crs
)

extracted <- terra::extract(covariates, points, ID = FALSE)
training_table <- dplyr::bind_cols(observations, extracted) |>
  dplyr::filter(!is.na(.data[[settings$target]]))
training_table[[settings$target]] <- factor(
  training_table[[settings$target]],
  levels = soil_classes
)

dir.create(dirname(paths$training_table), recursive = TRUE, showWarnings = FALSE)
utils::write.csv(training_table, paths$training_table, row.names = FALSE)

message(
  "Stage 1 complete: ", nrow(training_table), " observations × ",
  ncol(training_table), " columns."
)

