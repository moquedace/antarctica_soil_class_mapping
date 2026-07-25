# Stage 6 — structural checks for the main generated products ----------------

source("scripts/00_config.R")

if (!requireNamespace("terra", quietly = TRUE)) {
  stop("Install the terra package before running this stage.")
}

files <- c(
  probabilities = file.path(
    paths$probabilities, "median_class_probabilities.tif"
  ),
  ranked_classes = file.path(paths$ranked, "classes_rank_1_to_5.tif"),
  ranked_probabilities = file.path(
    paths$ranked, "probabilities_rank_1_to_5.tif"
  ),
  components = file.path(paths$mapping_units, "number_of_components.tif"),
  mapping_unit_code = file.path(paths$mapping_units, "mapping_unit_code.tif")
)

missing_files <- files[!file.exists(files)]
if (length(missing_files) > 0) {
  stop("Missing generated products: ", paste(names(missing_files), collapse = ", "))
}

rasters <- lapply(files, terra::rast)
reference <- rasters$probabilities[[1]]
geometry_ok <- vapply(
  rasters,
  function(x) terra::compareGeom(reference, x[[1]], stopOnError = FALSE),
  logical(1)
)
if (!all(geometry_ok)) {
  stop("Generated products do not share a common raster geometry.")
}

expected_layers <- c(
  probabilities = length(soil_classes),
  ranked_classes = settings$ranked_classes,
  ranked_probabilities = settings$ranked_classes,
  components = 1L,
  mapping_unit_code = 1L
)
found_layers <- vapply(rasters, terra::nlyr, integer(1))
if (!identical(unname(found_layers), unname(expected_layers))) {
  stop("Unexpected layer count in one or more products.")
}

value_ranges <- lapply(rasters, terra::minmax)
stopifnot(
  min(value_ranges$probabilities) >= 0,
  max(value_ranges$probabilities) <= 1,
  min(value_ranges$ranked_classes) >= 1,
  max(value_ranges$ranked_classes) <= length(soil_classes),
  min(value_ranges$ranked_probabilities) >= 0,
  max(value_ranges$ranked_probabilities) <= 1,
  min(value_ranges$components) >= 1,
  max(value_ranges$components) <= settings$ranked_classes
)

message("Stage 6 complete: geometry, layer counts, and value ranges are valid.")
