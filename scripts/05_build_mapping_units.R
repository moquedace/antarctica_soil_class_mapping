# Stage 5 — ranked probabilities -> uncertainty-aware soil mapping units ------
#
# Inputs:  derived/ranked/classes_rank_1_to_5.tif
#          derived/ranked/probabilities_rank_1_to_5.tif
# Outputs: derived/mapping_units/number_of_components.tif
#          derived/mapping_units/mapping_unit_code.tif
#          derived/mapping_units/mapping_units.gpkg

source("scripts/00_config.R")

if (!requireNamespace("terra", quietly = TRUE)) {
  stop("Install the terra package before running this stage.")
}

class_file <- file.path(paths$ranked, "classes_rank_1_to_5.tif")
probability_file <- file.path(paths$ranked, "probabilities_rank_1_to_5.tif")
if (!all(file.exists(c(class_file, probability_file)))) {
  stop("Run scripts/04_rank_probabilities.R first.")
}

ranked_classes <- terra::rast(class_file)
ranked_probabilities <- terra::rast(probability_file)
threshold <- settings$cumulative_probability

number_of_components <- terra::app(ranked_probabilities, function(values) {
  if (all(is.na(values))) {
    return(NA_integer_)
  }
  reached <- which(cumsum(replace(values, is.na(values), 0)) >= threshold)
  if (length(reached) == 0) length(values) else reached[1]
})
names(number_of_components) <- "number_of_components"

# Encode the ordered class combination as a unique integer. Base 20 is used
# because published class codes range from 1 to 19.
mapping_unit_code <- terra::app(
  c(ranked_classes, number_of_components),
  function(values) {
    classes <- values[seq_len(settings$ranked_classes)]
    n_components <- values[settings$ranked_classes + 1]
    if (is.na(n_components)) {
      return(NA_integer_)
    }
    keep <- seq_len(n_components)
    sum(classes[keep] * 20 ^ (keep - 1))
  }
)
names(mapping_unit_code) <- "mapping_unit_code"

terra::writeRaster(
  number_of_components,
  file.path(paths$mapping_units, "number_of_components.tif"),
  overwrite = TRUE,
  datatype = "INT1U",
  gdal = "COMPRESS=DEFLATE"
)
terra::writeRaster(
  mapping_unit_code,
  file.path(paths$mapping_units, "mapping_unit_code.tif"),
  overwrite = TRUE,
  datatype = "INT4S",
  gdal = "COMPRESS=DEFLATE"
)

mapping_units <- terra::as.polygons(mapping_unit_code, dissolve = TRUE)
terra::writeVector(
  mapping_units,
  file.path(paths$mapping_units, "mapping_units.gpkg"),
  overwrite = TRUE
)

message("Stage 5 complete: one- to five-component mapping units.")

