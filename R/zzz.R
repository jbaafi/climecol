# R/zzz.R
# ------------------------------------------------------------------------------
# Central place to declare global variables used in non-standard evaluation (NSE)
# so R CMD check doesn’t complain about “no visible binding for global variable”.
#
# Only include *column names* or symbols that appear unquoted inside dplyr/data-
# masked expressions. Do NOT list regular functions here (e.g., `approx`); those
# should be namespaced (stats::approx) or imported via roxygen.
# ------------------------------------------------------------------------------

utils::globalVariables(c(
  "n_days",
  "n_missing",
  "day_of_year",
  "mean_temp",
  "fitted_sin1",
  "fitted_sin2",
  "fitted",
  "model",
  "avg_photo"
))

# If future NSE notes appear, add their symbols here, e.g.:
# utils::globalVariables(c("some_new_col"))
