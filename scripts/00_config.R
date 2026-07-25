# Project configuration -------------------------------------------------------
#
# Set the project root before sourcing this file when running from elsewhere:
# options(antarctica.project_root = "path/to/your/project")

project_root <- normalizePath(
  getOption("antarctica.project_root", getwd()),
  winslash = "/",
  mustWork = TRUE
)

paths <- list(
  observations = file.path(project_root, "data", "soil_observations.csv"),
  covariates = file.path(project_root, "data", "covariates_8m"),
  training_table = file.path(project_root, "derived", "training_table.csv"),
  models = file.path(project_root, "derived", "models"),
  probabilities = file.path(project_root, "derived", "probabilities"),
  ranked = file.path(project_root, "derived", "ranked"),
  mapping_units = file.path(project_root, "derived", "mapping_units")
)

settings <- list(
  crs = "ESRI:102021",
  coordinate_columns = c("X", "Y"),
  target = "class_st3",
  train_fraction = 0.80,
  runs = 100L,
  seed = 666L,
  correlation_cutoff = 0.95,
  rfe_folds = 5L,
  model_folds = 10L,
  model_repeats = 3L,
  trees = 500L,
  ranked_classes = 5L,
  cumulative_probability = 0.50
)

factor_covariates <- c(
  "curvature_classification",
  "geology",
  "geomorphons",
  "landforms_tpi_based",
  "surface_specific_points",
  "terrain_surface_classification_iwahashi",
  "valley_idx"
)

soil_classes <- c(
  "anhyorthels_anhyturbels",
  "aquiturbels",
  "aquorthels",
  "cryopsamments",
  "dystrogelepts_humigelepts",
  "fibristels_sapristels",
  "gelaquents_psammaquents",
  "gelaquepts_petraquepts",
  "gelifluvents",
  "gelorthents",
  "haplogelepts",
  "haplohemists_cryofibrists",
  "haplorthels",
  "haploturbels",
  "psammorthels",
  "psammoturbels",
  "rocky_outcrops",
  "umbrothels_umbriturbels",
  "vitrigelands"
)

invisible(lapply(
  paths[c("models", "probabilities", "ranked", "mapping_units")],
  dir.create,
  recursive = TRUE,
  showWarnings = FALSE
))

