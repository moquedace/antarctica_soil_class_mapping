# Stage 2 — model-ready table -> repeated Random Forest ensemble --------------
#
# Input:  derived/training_table.csv
# Output: derived/models/rf_ensemble.rds
#         derived/models/performance.csv

source("scripts/00_config.R")

required_packages <- c("caret", "randomForest", "dplyr")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)
]
if (length(missing_packages) > 0) {
  stop("Install required packages: ", paste(missing_packages, collapse = ", "))
}
if (!file.exists(paths$training_table)) {
  stop("Run scripts/01_prepare_training_data.R first.")
}

data <- utils::read.csv(paths$training_table, check.names = FALSE)
data[[settings$target]] <- factor(data[[settings$target]], levels = soil_classes)
data <- data[!is.na(data[[settings$target]]), , drop = FALSE]

excluded <- c(settings$coordinate_columns, settings$target)
candidate_predictors <- setdiff(names(data), excluded)
numeric_predictors <- candidate_predictors[
  vapply(data[candidate_predictors], is.numeric, logical(1))
]

nzv <- caret::nearZeroVar(data[numeric_predictors], names = TRUE)
numeric_predictors <- setdiff(numeric_predictors, nzv)

correlation_matrix <- stats::cor(
  data[numeric_predictors],
  use = "pairwise.complete.obs"
)
correlated <- caret::findCorrelation(
  correlation_matrix,
  cutoff = settings$correlation_cutoff,
  names = TRUE
)
predictors <- union(
  setdiff(numeric_predictors, correlated),
  intersect(candidate_predictors, factor_covariates)
)

if (length(predictors) < 2) {
  stop("Fewer than two predictors remain after filtering.")
}

fit_run <- function(run_id) {
  set.seed(settings$seed + run_id)
  train_index <- caret::createDataPartition(
    data[[settings$target]],
    p = settings$train_fraction,
    list = FALSE
  )
  train_data <- data[train_index, c(settings$target, predictors), drop = FALSE]
  test_data <- data[-train_index, c(settings$target, predictors), drop = FALSE]

  rfe_control <- caret::rfeControl(
    functions = caret::rfFuncs,
    method = "cv",
    number = settings$rfe_folds
  )
  sizes <- unique(pmin(c(5, 10, 20, 40, length(predictors)), length(predictors)))
  rfe_fit <- caret::rfe(
    x = train_data[predictors],
    y = train_data[[settings$target]],
    sizes = sizes,
    rfeControl = rfe_control,
    metric = "Kappa"
  )
  selected <- caret::predictors(rfe_fit)

  model_control <- caret::trainControl(
    method = "repeatedcv",
    number = settings$model_folds,
    repeats = settings$model_repeats,
    classProbs = TRUE
  )
  model <- caret::train(
    x = train_data[selected],
    y = train_data[[settings$target]],
    method = "rf",
    metric = "Kappa",
    tuneLength = 5,
    trControl = model_control,
    ntree = settings$trees,
    nodesize = 1
  )

  predicted <- stats::predict(model, newdata = test_data[selected])
  confusion <- caret::confusionMatrix(predicted, test_data[[settings$target]])
  by_class <- confusion$byClass

  list(
    run = run_id,
    model = model,
    predictors = selected,
    performance = data.frame(
      run = run_id,
      accuracy = unname(confusion$overall["Accuracy"]),
      kappa = unname(confusion$overall["Kappa"]),
      balanced_accuracy = mean(by_class[, "Balanced Accuracy"], na.rm = TRUE),
      f1 = mean(by_class[, "F1"], na.rm = TRUE)
    )
  )
}

ensemble <- lapply(seq_len(settings$runs), fit_run)
performance <- dplyr::bind_rows(lapply(ensemble, `[[`, "performance"))

saveRDS(ensemble, file.path(paths$models, "rf_ensemble.rds"))
utils::write.csv(
  performance,
  file.path(paths$models, "performance.csv"),
  row.names = FALSE
)

message("Stage 2 complete: ", length(ensemble), " fitted RF models.")
