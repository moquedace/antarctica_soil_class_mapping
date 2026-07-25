# Stage 3 — fitted ensemble + covariates -> median class probabilities --------
#
# Inputs:  derived/models/rf_ensemble.rds
#          data/covariates_8m/*.tif
# Output:  derived/probabilities/median_class_probabilities.tif

source("scripts/00_config.R")

if (!requireNamespace("terra", quietly = TRUE)) {
  stop("Install the terra package before running this stage.")
}

ensemble_file <- file.path(paths$models, "rf_ensemble.rds")
if (!file.exists(ensemble_file)) {
  stop("Run scripts/02_fit_rf_ensemble.R first.")
}

covariate_files <- list.files(
  paths$covariates,
  pattern = "\\.tif$",
  full.names = TRUE
)
if (length(covariate_files) == 0) {
  stop("No covariate GeoTIFFs found in: ", paths$covariates)
}

covariates <- terra::rast(covariate_files)
names(covariates) <- tools::file_path_sans_ext(basename(covariate_files))
ensemble <- readRDS(ensemble_file)

predict_probabilities <- function(model, data) {
  as.data.frame(stats::predict(model, newdata = data, type = "prob"))
}

run_files <- character(length(ensemble))
for (i in seq_along(ensemble)) {
  run <- ensemble[[i]]
  missing_predictors <- setdiff(run$predictors, names(covariates))
  if (length(missing_predictors) > 0) {
    stop(
      "Covariate stack is missing predictors for run ", i, ": ",
      paste(missing_predictors, collapse = ", ")
    )
  }

  run_files[i] <- file.path(
    paths$probabilities,
    sprintf("run_%03d_probabilities.tif", i)
  )
  terra::predict(
    covariates[[run$predictors]],
    run$model,
    fun = predict_probabilities,
    na.rm = TRUE,
    filename = run_files[i],
    overwrite = TRUE
  )
}

run_stack <- terra::rast(run_files)
n_classes <- length(soil_classes)
median_layers <- vector("list", n_classes)

for (class_id in seq_len(n_classes)) {
  layer_ids <- seq(class_id, terra::nlyr(run_stack), by = n_classes)
  median_layers[[class_id]] <- terra::app(
    run_stack[[layer_ids]],
    median,
    na.rm = TRUE
  )
}

median_probabilities <- terra::rast(median_layers)
names(median_probabilities) <- soil_classes
terra::writeRaster(
  median_probabilities,
  file.path(paths$probabilities, "median_class_probabilities.tif"),
  overwrite = TRUE,
  gdal = "COMPRESS=DEFLATE"
)

message("Stage 3 complete: median probability maps for ", n_classes, " classes.")

