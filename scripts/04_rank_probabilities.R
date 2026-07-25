# Stage 4 — class probabilities -> ranked classes and ranked probabilities ----
#
# Input:   derived/probabilities/median_class_probabilities.tif
# Outputs: derived/ranked/classes_rank_1_to_5.tif
#          derived/ranked/probabilities_rank_1_to_5.tif

source("scripts/00_config.R")

if (!requireNamespace("terra", quietly = TRUE)) {
  stop("Install the terra package before running this stage.")
}

probability_file <- file.path(
  paths$probabilities,
  "median_class_probabilities.tif"
)
if (!file.exists(probability_file)) {
  stop("Run scripts/03_predict_class_probabilities.R first.")
}

probabilities <- terra::rast(probability_file)
k <- settings$ranked_classes

ranked_classes <- terra::app(probabilities, function(values) {
  if (all(is.na(values))) {
    return(rep(NA_integer_, k))
  }
  order(values, decreasing = TRUE, na.last = TRUE)[seq_len(k)]
})

ranked_probabilities <- terra::app(probabilities, function(values) {
  if (all(is.na(values))) {
    return(rep(NA_real_, k))
  }
  sort(values, decreasing = TRUE, na.last = TRUE)[seq_len(k)]
})

names(ranked_classes) <- paste0("class_rank_", seq_len(k))
names(ranked_probabilities) <- paste0("probability_rank_", seq_len(k))

terra::writeRaster(
  ranked_classes,
  file.path(paths$ranked, "classes_rank_1_to_5.tif"),
  overwrite = TRUE,
  datatype = "INT1U",
  gdal = "COMPRESS=DEFLATE"
)
terra::writeRaster(
  ranked_probabilities,
  file.path(paths$ranked, "probabilities_rank_1_to_5.tif"),
  overwrite = TRUE,
  datatype = "FLT4S",
  gdal = "COMPRESS=DEFLATE"
)

message("Stage 4 complete: ", k, " ranked classes and probabilities.")

